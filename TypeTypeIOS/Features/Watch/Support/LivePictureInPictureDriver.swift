import AVFoundation
import AVKit
import Foundation

/// Twitch-style in-app Picture in Picture: on minimize the app hides its
/// video surface and floats the real system PiP window over the app. Falls
/// back to the in-app mini player card when PiP is unavailable or fails to
/// start (isEngaged stays false in that case).
@MainActor
final class LivePictureInPictureDriver: NSObject {
  private(set) var isEngaged = false
  /// Fired whenever engagement changes (started, failed, stopped).
  var onChange: (() -> Void)?

  private var pipController: AVPictureInPictureController?
  private var contentLayer: AVPlayerLayer?
  private var isRestoring = false
  private var onRestore: (() -> Void)?
  private var onClose: (() -> Void)?

  var isAvailable: Bool {
    AVPictureInPictureController.isPictureInPictureSupported()
  }

  func attach(player: AVPlayer) {
    if let pipController {
      contentLayer?.player = player
      _ = pipController
      return
    }
    let layer = AVPlayerLayer()
    layer.player = player
    contentLayer = layer
    let controller = AVPictureInPictureController(playerLayer: layer)
    controller.delegate = self
    controller.canStartPictureInPictureAutomaticallyFromInline = false
    pipController = controller
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
}

extension LivePictureInPictureDriver: AVPictureInPictureControllerDelegate {
  nonisolated func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    Task { @MainActor [weak self] in
      self?.onChange?()
    }
  }

  nonisolated func pictureInPictureControllerFailedToStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
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
