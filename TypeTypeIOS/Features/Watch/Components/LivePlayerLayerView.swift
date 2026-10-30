import AVKit
import SwiftUI

@MainActor
private final class LiveAVPlayerViewController: AVPlayerViewController {
  var onWillTransition:
    ((UIViewControllerTransitionCoordinator) -> Void)?

  override func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    onWillTransition?(coordinator)
    super.viewWillTransition(to: size, with: coordinator)
  }
}

struct LivePlayerLayerView: UIViewControllerRepresentable {
  let player: AVPlayer
  let controller: LivePlayerController
  var onSwipeAdjustment: ((PlayerSwipeAdjustmentEvent) -> Void)? = nil
  var onHorizontalSeek: ((PlayerHorizontalSeekEvent) -> Void)? = nil
  var onFullscreenExit: (() -> Void)? = nil
  var onPictureInPictureUIRestore:
    (((@escaping (Bool) -> Void)) -> Void)? = nil
  var showsSystemControls = true

  func makeCoordinator() -> LivePlayerLayerCoordinator {
    LivePlayerLayerCoordinator(controller: controller)
  }

  func makeUIViewController(
    context: Context
  ) -> AVPlayerViewController {
    let playerController = LiveAVPlayerViewController()
    playerController.player = player
    playerController.showsPlaybackControls = showsSystemControls
    playerController.allowsPictureInPicturePlayback = true
    // No auto-PiP while the native player shows the landscape full screen.
    playerController.canStartPictureInPictureAutomaticallyFromInline = false
    playerController.entersFullScreenWhenPlaybackBegins = false
    playerController.exitsFullScreenWhenPlaybackEnds = false
    playerController.videoGravity = controller.imageMode.videoGravity
    playerController.view.backgroundColor = .black
    playerController.delegate = context.coordinator
    updateGestures(context.coordinator.surfaceGestures)
    context.coordinator.surfaceGestures.install(in: playerController.view)
    context.coordinator.pictureInPictureUIRestoreHandler =
      onPictureInPictureUIRestore
    playerController.onWillTransition = {
      [weak coordinator = context.coordinator] transitionCoordinator in
      coordinator?.preservePlayback(across: transitionCoordinator)
    }
    context.coordinator.install(in: playerController)
    controller.pictureInPicture.installContentLayer(
      on: playerController.view,
      player: player
    )
    return playerController
  }

  func updateUIViewController(
    _ playerController: AVPlayerViewController,
    context: Context
  ) {
    if playerController.player !== player {
      playerController.player = player
    }
    playerController.videoGravity = controller.imageMode.videoGravity
    context.coordinator.update(controller, in: playerController)
    playerController.canStartPictureInPictureAutomaticallyFromInline =
      controller.nativePlayback == nil && !controller.isPresentingFullscreen
    controller.pictureInPicture.installContentLayer(
      on: playerController.view,
      player: player
    )
    if controller.pictureInPicture.consumeControlsRefresh() {
      playerController.showsPlaybackControls = false
      DispatchQueue.main.async {
        playerController.showsPlaybackControls = showsSystemControls
      }
    }
    updateGestures(context.coordinator.surfaceGestures)
    context.coordinator.pictureInPictureUIRestoreHandler =
      onPictureInPictureUIRestore
  }

  private func updateGestures(_ gestures: LivePlayerSurfaceGestures) {
    gestures.swipeHandler = onSwipeAdjustment
    gestures.horizontalSeekHandler = onHorizontalSeek
    gestures.fullscreenExitHandler = onFullscreenExit
  }

  static func dismantleUIViewController(
    _ playerController: AVPlayerViewController,
    coordinator: LivePlayerLayerCoordinator
  ) {
    let shouldContinuePlayback =
      playerController.player?.timeControlStatus == .playing
      || coordinator.playbackWasIntended
      || coordinator.controller.presentationResumeTask != nil
    coordinator.invalidate()
    (playerController as? LiveAVPlayerViewController)?
      .onWillTransition = nil
    playerController.delegate = nil
    playerController.player = nil
    coordinator.controller.preservePlaybackAfterViewDetach(
      shouldContinue: shouldContinuePlayback
    )
  }
}
