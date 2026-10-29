import AVFoundation
import AVKit
import UIKit

/// On minimize the app hides its video and floats the system PiP window over itself. The content layer
/// must stay in the visible player hierarchy: a detached one renders nothing.
@MainActor
final class LivePictureInPictureDriver: NSObject, ObservableObject {
  @Published private(set) var isEngaged = false
  /// True while waiting for the system to allow a PiP start (during loading
  /// the window cannot open yet). Suppresses the fallback card.
  @Published private(set) var isPendingStart = false
  /// The system's own truth about the window: a late-confirmed start can
  /// leave `isEngaged` behind reality.
  var isSystemActive: Bool {
    pipController?.isPictureInPictureActive ?? false
  }
  /// Fired whenever engagement changes (started, failed, stopped).
  var onChange: (() -> Void)?

  private var pipController: AVPictureInPictureController?
  private var contentLayer: AVPlayerLayer?
  private var nativeLayer: AVSampleBufferDisplayLayer?
  private weak var hostView: UIView?
  private var isRestoring = false
  private var controlsRefreshPending = false
  private var didStartConfirmed = false
  private var startVerificationTask: Task<Void, Never>?
  private var pendingStartTask: Task<Void, Never>?
  private var onRestore: (() -> Void)?
  private var onClose: (() -> Void)?

  var isAvailable: Bool {
    AVPictureInPictureController.isPictureInPictureSupported()
  }

  /// Installs the PiP content layer into the live player view (kept behind
  /// the player's own controls) and keeps it sized to the host.
  func installContentLayer(on view: UIView, player: AVPlayer) {
    if contentLayer == nil {
      let layer = AVPlayerLayer()
      layer.videoGravity = .resizeAspect
      // Hidden unless PiP runs: a live player layer inside the player view
      // corrupts the blur/backdrop AVKit's controls are drawn on ("invalid
      // image bits/pixel"): the controls end up invisible but tappable.
      layer.isHidden = true
      contentLayer = layer
    }
    if nativeLayer != nil || pipController == nil, let layer = contentLayer {
      nativeLayer = nil
      pipController = isAvailable ? AVPictureInPictureController(playerLayer: layer) : nil
      pipController?.delegate = self
      pipController?.canStartPictureInPictureAutomaticallyFromInline = false
    }
    contentLayer?.player = player
    contentLayer?.isHidden = !isEngaged
    if contentLayer?.superlayer !== view.layer {
      contentLayer?.removeFromSuperlayer()
      view.layer.insertSublayer(contentLayer ?? CALayer(), at: 0)
    }
    hostView = view
    relayout()
  }

  /// Poster placeholder until frames arrive: the system refuses a PiP start on an empty layer.
  func loadPoster(url: URL?) async {
    guard let url else { return }
    let posterStart = DispatchTime.now()
    defer {
      let ms = Int(Double(DispatchTime.now().uptimeNanoseconds - posterStart.uptimeNanoseconds) / 1e6)
      AppLogger.playback.info("pip timing: poster took \(ms, privacy: .public)ms")
      Self.lastTimingLog = "poster \(ms)ms | " + Self.lastTimingLog
    }
    // A slow poster download must not hold the PiP start hostage: race the
    // fetch against a short budget and start regardless (an empty layer
    // falls back to the in-app card, which is an acceptable degradation).
    let image: UIImage? = await withTaskGroup(
      of: UIImage?.self
    ) { group in
      group.addTask {
        guard let (data, _) = try? await URLSession.shared.data(from: url)
        else { return nil }
        return UIImage(data: data)
      }
      group.addTask {
        try? await Task.sleep(for: .milliseconds(1_200))
        return nil
      }
      let first = await group.next() ?? nil
      group.cancelAll()
      return first
    }
    guard let image, let cgImage = image.cgImage else { return }
    contentLayer?.contents = cgImage
    contentLayer?.contentsGravity = .resizeAspect
  }

  func installNativeContent(
    layer: AVSampleBufferDisplayLayer,
    playback: AVPictureInPictureSampleBufferPlaybackDelegate
  ) {
    guard isAvailable, nativeLayer !== layer else { return }
    contentLayer?.isHidden = true
    nativeLayer = layer
    let controller = AVPictureInPictureController(
      contentSource: .init(sampleBufferDisplayLayer: layer, playbackDelegate: playback)
    )
    controller.delegate = self
    // The SYSTEM performs the background hand-off itself and cannot lose
    // the race against its own suspension (a manual start at .inactive
    // lost it: "scene invalidated before create completion").
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    AppLogger.playback
      .info("pip engine: native content installed")
    pipController = controller
  }

  func invalidatePlaybackState() {
    if nativeLayer != nil {
      pipController?.invalidatePlaybackState()
    }
  }

  func relayout() {
    guard let hostView, let contentLayer else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    contentLayer.frame = hostView.bounds
    CATransaction.commit()
  }

  /// Marks the controls for a forced refresh (e.g. when the player surface
  /// reappears after a PiP round trip).
  func markControlsRefresh() {
    controlsRefreshPending = true
  }

  /// True once after every PiP stop: AVKit can leave its controls hidden
  /// after a hand-back, the player layer uses this to force them back.
  func consumeControlsRefresh() -> Bool {
    defer { controlsRefreshPending = false }
    return controlsRefreshPending
  }

  private var startRequestedAt: DispatchTime?
  /// Debug-only: the last PiP timings, shown in the notice HUD.
  nonisolated(unsafe) static var lastTimingLog = ""

  func start(
    onRestore: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    startRequestedAt = DispatchTime.now()
    guard isAvailable, let pipController, !isEngaged, !isPendingStart else {
      return
    }
    // The system animates the window from the layer's rect.
    relayout()
    if nativeLayer == nil {
      contentLayer?.isHidden = false
    }
    self.onRestore = onRestore
    self.onClose = onClose
    if pipController.isPictureInPicturePossible {
      performStart()
    } else {
      isPendingStart = true
      onChange?()
      pendingStartTask?.cancel()
      pendingStartTask = Task { @MainActor [weak self] in
        let possible = await pipController.becomesPossible(within: .seconds(15))
        guard let self, isPendingStart, !Task.isCancelled else { return }
        isPendingStart = false
        if possible {
          performStart()
        } else {
          // Never became possible: release and let the in-app card show.
          onChange?()
        }
      }
    }
  }

  private func performStart() {
    guard let pipController else { return }
    relayout()
    contentLayer?.isHidden = false
    isEngaged = true
    didStartConfirmed = false
    onChange?()
    let startCall = DispatchTime.now()
    pipController.startPictureInPicture()
    let startMs = Int(
      Double(DispatchTime.now().uptimeNanoseconds - startCall.uptimeNanoseconds) / 1e6
    )
    AppLogger.playback
      .info("pip timing: startPictureInPicture blocked \(startMs, privacy: .public)ms")
    Self.lastTimingLog = "start blocked \(startMs)ms | " + Self.lastTimingLog
    // If neither didStart nor failedToStart arrives, the window never came
    // up: release the engagement so the in-app card can show instead.
    startVerificationTask?.cancel()
    startVerificationTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1.5))
      guard let self, isEngaged, !didStartConfirmed else { return }
      isEngaged = false
      contentLayer?.isHidden = true
      onChange?()
    }
  }

  /// Aborts a pending start (e.g. the playback was closed meanwhile).
  func cancelPendingStart() {
    isPendingStart = false
    pendingStartTask?.cancel()
    pendingStartTask = nil
    onChange?()
  }

  func stop() {
    pipController?.stopPictureInPicture()
  }

  /// Stops PiP and keeps playing. Engagement drops first so the notice is gone before the window returns.
  func bringInline() {
    AppLogger.playback.info("pip driver: bring inline requested")
    // The system is the truth: a late-confirmed window can be up while the
    // bookkeeping flag says otherwise.
    let systemActive = pipController?.isPictureInPictureActive ?? false
    guard isEngaged || systemActive else {
      AppLogger.playback.info("pip driver: bring inline skipped, not engaged")
      return
    }
    isEngaged = false
    onChange?()
    isRestoring = true
    relayout()
    pipController?.stopPictureInPicture()
  }
}

extension LivePictureInPictureDriver: AVPictureInPictureControllerDelegate {
  nonisolated func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      didStartConfirmed = true
      // Late confirms arrive after the start verification gave up and
      // dropped the flag: but the system window IS up then, and the return
      // path needs the flag to hand the video back.
      isEngaged = true
      if let requestedAt = startRequestedAt {
        let ms = Int(Double(DispatchTime.now().uptimeNanoseconds - requestedAt.uptimeNanoseconds) / 1e6)
        AppLogger.playback
          .info("pip timing: request to confirmed took \(ms, privacy: .public)ms")
        Self.lastTimingLog = "confirm \(ms)ms | " + Self.lastTimingLog
      }
      onChange?()
    }
  }

  nonisolated func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      // Fall back to the in-app mini player card.
      isEngaged = false
      contentLayer?.isHidden = true
      onChange?()
    }
  }

  nonisolated func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
      completionHandler: @escaping (Bool) -> Void
  ) {
    Task { @MainActor [weak self] in
      guard let self else {
        completionHandler(false)
        return
      }
      // User tapped the PiP expand button: bring the player back first.
      isRestoring = true
      AppLogger.playback.info("pip driver: restore requested")
      onRestore?()
      completionHandler(true)
    }
  }

  nonisolated func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      isEngaged = false
      contentLayer?.isHidden = true
      controlsRefreshPending = true
      let wasRestoring = isRestoring
      isRestoring = false
      AppLogger.playback
        .info("pip driver: did stop, restoring=\(wasRestoring, privacy: .public)")
      onChange?()
      if !wasRestoring {
        // User closed the PiP window: end playback like the system expects.
        onClose?()
      }
    }
  }
}
