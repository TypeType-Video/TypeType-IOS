import AVKit

extension LivePlayerLayerCoordinator {
  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    willBeginFullScreenPresentationWithAnimationCoordinator
      coordinator: UIViewControllerTransitionCoordinator
  ) {
    isEndingFullScreen = false
    isFullScreenPresented = true
    fullScreenPlaybackWasIntended =
      playbackWasIntended
      || controller.player.timeControlStatus == .playing
      || controller.state == .playing
    transition(
      playerViewController,
      toFullScreen: true,
      shouldResumePlayback: fullScreenPlaybackWasIntended,
      with: coordinator
    )
  }

  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    willEndFullScreenPresentationWithAnimationCoordinator
      coordinator: UIViewControllerTransitionCoordinator
  ) {
    let shouldResumePlayback =
      fullScreenPlaybackWasIntended
      || playbackWasIntended
      || controller.player.timeControlStatus == .playing
      || controller.state == .playing
    isEndingFullScreen = true
    isFullScreenPresented = false
    transition(
      playerViewController,
      toFullScreen: false,
      shouldResumePlayback: shouldResumePlayback,
      with: coordinator
    )
  }

  func playerViewControllerWillStartPictureInPicture(
    _ playerViewController: AVPlayerViewController
  ) {
    beginPictureInPictureTransition()
  }

  func playerViewControllerDidStartPictureInPicture(
    _ playerViewController: AVPlayerViewController
  ) {
    completePictureInPictureTransition()
  }

  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    completePictureInPictureTransition()
  }

  func playerViewControllerWillStopPictureInPicture(
    _ playerViewController: AVPlayerViewController
  ) {
    beginPictureInPictureTransition()
  }

  func playerViewControllerDidStopPictureInPicture(
    _ playerViewController: AVPlayerViewController
  ) {
    completePictureInPictureTransition()
  }

  func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(
    _ playerViewController: AVPlayerViewController
  ) -> Bool {
    false
  }

  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
      completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(true)
  }

  private func transition(
    _ playerViewController: AVPlayerViewController,
    toFullScreen: Bool,
    shouldResumePlayback: Bool,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    presentationTransitionInProgress = true
    pendingPauseIntentTask?.cancel()
    resumeAfterTransitionTask?.cancel()
    settleTransitionTask?.cancel()
    // AVKit reparents its content view while entering and leaving full
    // screen. Hosting views must leave that subtree during the move.
    remove()

    coordinator.animate(
      alongsideTransition: nil
    ) { [weak self, weak playerViewController] context in
      guard let self, let playerViewController else { return }
      install(in: playerViewController)
      alignSponsorBanner(
        toTrailingEdge: context.isCancelled
          ? !toFullScreen
          : toFullScreen
      )
      guard shouldResumePlayback else {
        presentationTransitionInProgress = false
        isEndingFullScreen = false
        return
      }
      playbackWasIntended = true
      schedulePlaybackResume()
      settlePlaybackPreservationWindow(
        checks: toFullScreen ? 4 : 20
      )
    }
  }

  private func alignSponsorBanner(toTrailingEdge: Bool) {
    sponsorCenterConstraint?.isActive = !toTrailingEdge
    sponsorTrailingConstraint?.isActive = toTrailingEdge
    hostedViews.first?.superview?.layoutIfNeeded()
  }
}
