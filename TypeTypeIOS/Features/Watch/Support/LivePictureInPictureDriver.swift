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
  /// Fired whenever engagement changes (started, failed, stopped).
  var onChange: (() -> Void)?

  private var pipController: AVPictureInPictureController?
  private var contentLayer: AVPlayerLayer?
  private weak var hostView: UIView?
  private var isRestoring = false
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
      contentLayer = layer
      if isAvailable, let controller = AVPictureInPictureController(playerLayer: layer) {
        controller.delegate = self
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        pipController = controller
      }
    }
    contentLayer?.player = player
    if contentLayer?.superlayer !== view.layer {
      contentLayer?.removeFromSuperlayer()
      view.layer.insertSublayer(contentLayer ?? CALayer(), at: 0)
    }
    hostView = view
    relayout()
  }

  func relayout() {
    guard let hostView, let contentLayer else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    contentLayer.frame = hostView.bounds
    CATransaction.commit()
  }

  func start(
    onRestore: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    guard isAvailable, let pipController, !isEngaged else { return }
    self.onRestore = onRestore
    self.onClose = onClose
    isEngaged = true
    onChange?()
    pipController.startPictureInPicture()
  }

  func stop() {
    pipController?.stopPictureInPicture()
  }

  /// Returns the video to the app surface: stops PiP but keeps playback
  /// running (the stop handler is told this is a restore, not a close).
  func bringInline() {
    guard isEngaged else { return }
    isRestoring = true
    pipController?.stopPictureInPicture()
  }
}

extension LivePictureInPictureDriver: AVPictureInPictureControllerDelegate {
  nonisolated func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      self?.onChange?()
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
      let wasRestoring = isRestoring
      isRestoring = false
      onChange?()
      if !wasRestoring {
        // User closed the PiP window: end playback like the system expects.
        onClose?()
      }
    }
  }
}
