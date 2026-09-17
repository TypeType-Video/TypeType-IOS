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

  func makeCoordinator() -> LivePlayerLayerCoordinator {
    LivePlayerLayerCoordinator(controller: controller)
  }

  func makeUIViewController(
    context: Context
  ) -> AVPlayerViewController {
    let playerController = LiveAVPlayerViewController()
    playerController.player = player
    playerController.showsPlaybackControls = true
    playerController.allowsPictureInPicturePlayback = true
    playerController.canStartPictureInPictureAutomaticallyFromInline = true
    playerController.entersFullScreenWhenPlaybackBegins = false
    playerController.exitsFullScreenWhenPlaybackEnds = false
    playerController.videoGravity = controller.imageMode.videoGravity
    playerController.view.backgroundColor = .black
    playerController.delegate = context.coordinator
    playerController.onWillTransition = {
      [weak coordinator = context.coordinator] transitionCoordinator in
      coordinator?.preservePlayback(across: transitionCoordinator)
    }
    context.coordinator.install(in: playerController)
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
