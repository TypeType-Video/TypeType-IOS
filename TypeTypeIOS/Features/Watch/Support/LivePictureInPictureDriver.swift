import AVFoundation
import AVKit
import UIKit

// The content layer must stay in the visible player hierarchy: a detached one renders nothing.
@MainActor
final class LivePictureInPictureDriver: NSObject, ObservableObject {
  @Published private(set) var isEngaged = false
  @Published private(set) var isPendingStart = false
  var isSystemActive: Bool {
    pipController?.isPictureInPictureActive ?? false
  }
  var onChange: (() -> Void)?

  private var pipController: AVPictureInPictureController?
  var contentLayer: AVPlayerLayer?
  private var nativeLayer: AVSampleBufferDisplayLayer?
  private weak var hostView: UIView?
  var poster: (url: URL, image: CGImage)?
  var isRestoring = false
  var controlsRefreshPending = false
  var didStartConfirmed = false
  private var startVerificationTask: Task<Void, Never>?
  private var pendingStartTask: Task<Void, Never>?
  var onRestore: (() -> Void)?
  var onClose: (() -> Void)?
  var onInline: (() -> Void)?

  var isAvailable: Bool {
    AVPictureInPictureController.isPictureInPictureSupported()
  }

  func installContentLayer(on view: UIView, player: AVPlayer) {
    if contentLayer == nil {
      let layer = AVPlayerLayer()
      layer.videoGravity = .resizeAspect
      // Hidden unless PiP runs: a live player layer here corrupts the backdrop AVKit draws its controls on.
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
    applyPoster()
    contentLayer?.isHidden = !isEngaged
    if contentLayer?.superlayer !== view.layer {
      contentLayer?.removeFromSuperlayer()
      view.layer.insertSublayer(contentLayer ?? CALayer(), at: 0)
    }
    hostView = view
    relayout()
  }

  var usesNativeContent: Bool {
    nativeLayer != nil
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
    // The system does the background hand-off: a manual start at .inactive loses the race against suspension.
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

  func markControlsRefresh() {
    controlsRefreshPending = true
  }

  func consumeControlsRefresh() -> Bool {
    defer { controlsRefreshPending = false }
    return controlsRefreshPending
  }

  var startRequestedAt: DispatchTime?
  nonisolated(unsafe) static var lastTimingLog = ""

  func start(
    onRestore: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    startRequestedAt = DispatchTime.now()
    guard isAvailable, let pipController, !isEngaged, !isPendingStart else {
      return
    }
    relayout()
    if nativeLayer == nil {
      contentLayer?.isHidden = false
    }
    self.onRestore = onRestore
    self.onClose = onClose
    AppLogger.playback.info(
      "pip driver: start requested, possible=\(pipController.isPictureInPicturePossible, privacy: .public) window=\(self.hostView?.window != nil, privacy: .public)"
    )
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
          AppLogger.playback.error("pip driver: start given up, the system never allowed it")
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
    startVerificationTask?.cancel()
    startVerificationTask = Task { @MainActor [weak self] in
      try? await Task.sleep(for: .seconds(1.5))
      guard let self, isEngaged, !didStartConfirmed else { return }
      isEngaged = false
      contentLayer?.isHidden = true
      onChange?()
    }
  }

  func markEngaged(_ engaged: Bool) {
    isEngaged = engaged
  }

  func cancelPendingStart() {
    isPendingStart = false
    pendingStartTask?.cancel()
    pendingStartTask = nil
    onChange?()
  }

  func stop() {
    pipController?.stopPictureInPicture()
  }

  func bringInline(then onInline: (() -> Void)? = nil) {
    AppLogger.playback.info("pip driver: bring inline requested")
    // The system is the truth: a late-confirmed window can be up while the flag says otherwise.
    let systemActive = pipController?.isPictureInPictureActive ?? false
    guard isEngaged || systemActive else {
      AppLogger.playback.info("pip driver: bring inline skipped, not engaged")
      return
    }
    isEngaged = false
    onChange?()
    isRestoring = true
    self.onInline = onInline
    relayout()
    pipController?.stopPictureInPicture()
  }
}
