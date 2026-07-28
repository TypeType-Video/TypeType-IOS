import AVFoundation

extension LivePlayerLayerCoordinator {
  func settlePlaybackPreservationWindow(
    checks: Int = 4
  ) {
    settleTransitionTask?.cancel()
    settleTransitionTask = Task { @MainActor [weak self] in
      for _ in 0..<checks {
        do {
          try await Task.sleep(for: .milliseconds(200))
        } catch {
          return
        }
        guard let self else { return }
        guard playbackWasIntended,
          controller.player.currentItem != nil
        else {
          presentationTransitionInProgress = false
          return
        }
        if controller.player.timeControlStatus == .paused {
          controller.player.playImmediately(
            atRate: controller.playbackRate
          )
        }
      }
      guard let self else { return }
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
      controller.player.playImmediately(
        atRate: controller.playbackRate
      )
      resumeAfterTransitionTask = nil
    }
  }

  func cancelTransitionTasks() {
    pendingPauseIntentTask?.cancel()
    resumeAfterTransitionTask?.cancel()
    settleTransitionTask?.cancel()
  }
}
