import AVFoundation
import AVKit
import UIKit

/// Twitch-style in-app Picture in Picture: on minimize the app hides its
/// video surface and floats the real system PiP window over the app. The
/// PiP content layer must live in the visible player view hierarchy — a
/// detached layer renders no frames and the system window stays empty.
@MainActor
final class LivePictureInPictureDriver: NSObject, ObservableObject {
  @Published private(set) var isEngaged = false
  /// True while waiting for the system to allow a PiP start (during loading
  /// the window cannot open yet). Suppresses the fallback card.
  @Published private(set) var isPendingStart = false
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
      // image bits/pixel") — the controls end up invisible but tappable.
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

  /// Renders the poster into the content layer as a placeholder; the
  /// player's frames overwrite it once playback renders. Waits until the
  /// placeholder is in place — the system refuses a PiP start on an empty
  /// layer.
  func loadPoster(url: URL?) async {
    guard let url else { return }
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
    controller.canStartPictureInPictureAutomaticallyFromInline = false
    AppLogger.playback
      .info("pip engine: native content installed")
    pipController = controller
  }

  func invalidatePlaybackState() {
    if nativeLayer != nil {
      pipController?.invalidatePlaybackState()
    }
  }

  /// Drops the native PiP binding before the video layer crosses windows —
  /// a layer that leaves its window while bound to one gets auto-promoted
  /// to Picture in Picture by the system, which is what started PiP over
  /// the landscape full screen.
  func uninstallNativeContent() {
    AppLogger.playback
      .info("pip engine: native content released")
    nativeLayer = nil
    pipController = nil
    contentLayer?.isHidden = false
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

  func start(
    onRestore: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
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
    // The system refuses a PiP start while the player is still loading; wait
    // for the moment it becomes possible instead of failing silently.
    if pipController.isPictureInPicturePossible {
      performStart()
    } else {
      isPendingStart = true
      onChange?()
      pendingStartTask?.cancel()
      pendingStartTask = Task { @MainActor [weak self] in
        for _ in 0..<75 {
          try? await Task.sleep(for: .milliseconds(200))
          guard let self, isPendingStart else { return }
          if pipController.isPictureInPicturePossible {
            isPendingStart = false
            performStart()
            return
          }
        }
        // Never became possible: release and let the card show.
        isPendingStart = false
        onChange?()
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
    pipController.startPictureInPicture()
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

  /// Returns the video to the app surface: stops PiP but keeps playback
  /// running (the stop handler is told this is a restore, not a close).
  /// The engagement flag drops immediately so the notice overlay is gone
  /// before the system animates the window back into the player surface.
  func bringInline() {
    AppLogger.playback.info("pip driver: bring inline requested")
    guard isEngaged else {
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
      AppLogger.playback.info("pip driver: did start confirmed")
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
