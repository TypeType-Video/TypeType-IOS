import AVFoundation

extension LivePlayerLayerCoordinator {
  func settlePlaybackPreservationWindow(
    for window: Duration = .milliseconds(800)
  ) {
    settleTransitionTask?.cancel()
    let player = controller.player
    settleTransitionTask = Task { @MainActor [weak self] in
      await player.resumeEachPause(for: window) { [weak self] in
        guard let self, playbackWasIntended, player.currentItem != nil else { return }
        controller.playIfActive(rate: controller.playbackRate)
      }
      guard let self, !Task.isCancelled else { return }
      presentationTransitionInProgress = false
      isEndingFullScreen = false
      settleTransitionTask = nil
    }
  }

  func schedulePlaybackResume(
    after delay: Duration = .zero
  ) {
    resumeAfterTransitionTask?.cancel()
    resumeAfterTransitionTask = Task { @MainActor [weak self] in
      do {
        if delay > .zero {
          try await Task.sleep(for: delay)
        } else {
          await Task.yield()
        }
      } catch {
        return
      }
      guard let self,
        presentationTransitionInProgress,
        playbackWasIntended,
        controller.player.currentItem != nil
      else {
        return
      }
      controller.playIfActive(rate: controller.playbackRate)
      resumeAfterTransitionTask = nil
    }
  }

  func cancelTransitionTasks() {
    pendingPauseIntentTask?.cancel()
    resumeAfterTransitionTask?.cancel()
    settleTransitionTask?.cancel()
  }
}
