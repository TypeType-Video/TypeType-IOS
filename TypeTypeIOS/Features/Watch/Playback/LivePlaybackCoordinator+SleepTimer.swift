import Foundation

extension LivePlaybackCoordinator {
  func startSleepTimer(minutes: Int) {
    guard hasActivePlayback, (1...1_440).contains(minutes) else {
      return
    }
    startSleepTimer(duration: TimeInterval(minutes * 60))
  }

  func stopAtEndOfVideo() {
    guard hasActivePlayback else { return }
    sleepTimerTask?.cancel()
    sleepTimerTask = nil
    // The countdown must not start the next video after this video ends.
    cancelAutoplayCountdown()
    sleepTimer = LivePlaybackSleepTimerState(mode: .endOfVideo)
  }

  func cancelSleepTimer() {
    sleepTimerTask?.cancel()
    sleepTimerTask = nil
    sleepTimer = LivePlaybackSleepTimerState()
  }

  func handlePlaybackEnded() {
    if sleepTimer.mode == .endOfVideo {
      stopForTheNight()
      controller?.pause()
      return
    }
    // Quiet night state: nothing advances until the user interacts again.
    guard sleepTimer.mode != .stoppedForTheNight else { return }
    guard controller?.autoplayEnabled == true else { return }
    advanceAfterPlaybackEnd()
  }

  private func stopForTheNight() {
    sleepTimerTask?.cancel()
    sleepTimerTask = nil
    cancelAutoplayCountdown()
    sleepTimer = LivePlaybackSleepTimerState(mode: .stoppedForTheNight)
  }

  func startSleepTimer(duration: TimeInterval) {
    guard hasActivePlayback, duration > 0, duration <= 86_400 else {
      return
    }
    sleepTimerTask?.cancel()
    let deadline = ProcessInfo.processInfo.systemUptime + duration
    sleepTimer = LivePlaybackSleepTimerState(
      mode: .timed,
      duration: duration,
      remaining: duration
    )
    sleepTimerTask = Task { [weak self] in
      while !Task.isCancelled {
        guard let self else { return }
        let remaining = max(
          deadline - ProcessInfo.processInfo.systemUptime,
          0
        )
        sleepTimer.remaining = remaining
        if remaining == 0 {
          stopForTheNight()
          controller?.pause()
          return
        }
        let nanoseconds = UInt64(
          min(remaining, 1) * 1_000_000_000
        )
        try? await Task.sleep(nanoseconds: nanoseconds)
      }
    }
  }
}
