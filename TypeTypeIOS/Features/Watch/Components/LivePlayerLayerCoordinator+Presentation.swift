import AVKit

extension LivePlayerLayerCoordinator {
  func playerViewController(
    _ playerViewController: AVPlayerViewController,
    willBeginFullScreenPresentationWithAnimationCoordinator
      coordinator: UIViewControllerTransitionCoordinator
  ) {
    isEndingFullScreen = false
    isFullScreenPresented = true
    let playerIsPlaying: Bool = controller.player.timeControlStatus == .playing
    let stateIsPlaying: Bool = controller.state == .playing
    fullScreenPlaybackWasIntended = playbackWasIntended || playerIsPlaying || stateIsPlaying
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
    // AVKit can leave its controls hidden after a hand-back; the toggle must cross a run loop tick.
    playerViewController.showsPlaybackControls = false
    DispatchQueue.main.async {
      playerViewController.showsPlaybackControls = true
    }
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
    playerViewController.showsPlaybackControls = false
    DispatchQueue.main.async {
      playerViewController.showsPlaybackControls = true
      playerViewController.view.setNeedsLayout()
    }
    guard let handler = pictureInPictureUIRestoreHandler else {
      completionHandler(false)
      return
    }
    handler(completionHandler)
  }

  private func transition(
    _ playerViewController: AVPlayerViewController,
    toFullScreen: Bool,
    shouldResumePlayback: Bool,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    presentationTransitionInProgress = true
    LiveScreenOrientation.set(toFullScreen ? .landscape : .portrait)
    pendingPauseIntentTask?.cancel()
    resumeAfterTransitionTask?.cancel()
    settleTransitionTask?.cancel()
    // AVKit reparents its content view while entering and leaving full screen: hosting views must leave that subtree.
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
        for: toFullScreen ? .milliseconds(800) : .seconds(4)
      )
    }
  }

  private func alignSponsorBanner(toTrailingEdge: Bool) {
    sponsorCenterConstraint?.isActive = !toTrailingEdge
    sponsorTrailingConstraint?.isActive = toTrailingEdge
    hostedViews.first?.superview?.layoutIfNeeded()
  }
}
