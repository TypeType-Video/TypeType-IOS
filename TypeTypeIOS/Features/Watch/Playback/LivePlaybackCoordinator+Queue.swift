import Foundation

extension LivePlaybackCoordinator {
  func play(index: Int) {
    guard queue.isActive, queue.videos.indices.contains(index) else {
      return
    }
    if sleepTimer.mode == .stoppedForTheNight {
      sleepTimer = LivePlaybackSleepTimerState()
    }
    if index == queue.currentIndex {
      presentation = .expanded
      return
    }
    queue.currentIndex = index
    touchAndPersist()
    presentation = .expanded
    replacePlayback(with: queue.videos[index], autoplay: true)
  }

  func playNext(index: Int) {
    let previous = queue
    queue.moveNext(index: index)
    guard queue != previous else { return }
    touchAndPersist()
  }

  func remove(index: Int) {
    let previous = queue
    queue.remove(index: index)
    guard queue != previous else { return }
    touchAndPersist()
  }

  func remove(_ video: LiveVideoItem) {
    guard let index = queue.videos.firstIndex(
      where: { $0.url == video.url }
    ) else {
      return
    }
    remove(index: index)
  }

  func shuffleUpcoming() {
    let previous = queue
    queue.shuffleUpcoming()
    guard queue != previous else { return }
    touchAndPersist()
  }

  func cycleRepeatMode() {
    guard queue.isActive else { return }
    queue.repeatMode = queue.repeatMode.next
    touchAndPersist()
  }

  func clearQueueKeepingPlayback() {
    clearQueue()
  }

  func isQueued(_ video: LiveVideoItem) -> Bool {
    queue.isActive && queue.videos.contains { $0.url == video.url }
  }

  func advanceAfterPlaybackEnd() {
    guard queue.isActive else {
      // Like Android: outside a queue, autoplay plays the first related video after the countdown.
      guard let next = controller?.stream?.relatedStreams.first(where: { isPlayable($0) && $0.url != currentVideo?.url })
      else { return }
      startAutoplayCountdown(.related(next), seconds: appPreferences.preferences.playerAutoplayCountdownSeconds)
      return
    }
    if queue.repeatMode == .one {
      controller?.replay()
      return
    }
    guard let nextIndex = queue.nextIndex else {
      if let activeScope {
        queueStore.clear(activeScope)
      }
      return
    }
    let skipDelay = controller?.settings.skipPlaylistAutoplayScreen == true
    let seconds = skipDelay ? 0 : appPreferences.preferences.playerAutoplayCountdownSeconds
    startAutoplayCountdown(.queue(nextIndex), seconds: seconds)
  }

  private func startAutoplayCountdown(_ target: LivePendingAutoplay, seconds: Int) {
    guard seconds > 0 else {
      commitAutoplay(target)
      return
    }
    pendingAutoplay = target
    autoplayCountdownRemaining = seconds
    autoplayCountdownTask?.cancel()
    autoplayCountdownTask = Task { @MainActor [weak self] in
      var remaining = seconds
      while remaining > 0, !Task.isCancelled {
        guard let self else { return }
        self.autoplayCountdownRemaining = remaining
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled else { return }
        remaining -= 1
      }
      guard let self, !Task.isCancelled else { return }
      self.commitAutoplay(target)
    }
  }

  func skipAutoplayCountdown() {
    if sleepTimer.mode == .stoppedForTheNight {
      sleepTimer = LivePlaybackSleepTimerState()
    }
    guard let pendingAutoplay else { return }
    commitAutoplay(pendingAutoplay)
  }

  func cancelAutoplayCountdown() {
    autoplayCountdownTask?.cancel()
    autoplayCountdownTask = nil
    pendingAutoplay = nil
    autoplayCountdownRemaining = nil
  }

  private func commitAutoplay(_ target: LivePendingAutoplay) {
    cancelAutoplayCountdown()
    switch target {
    case let .queue(index):
      guard queue.isActive, queue.videos.indices.contains(index) else { return }
      queue.currentIndex = index
      touchAndPersist()
      replacePlayback(with: queue.videos[index], autoplay: true)
    case let .related(video):
      replacePlayback(with: video, autoplay: true)
    }
  }
}

enum LivePendingAutoplay: Equatable {
  case queue(Int)
  case related(LiveVideoItem)
}

extension LivePlaybackCoordinator {
  func prewarmNextQueueEntry() {
    guard queue.isActive,
      let nextIndex = queue.nextIndex,
      queue.videos.indices.contains(nextIndex)
    else {
      return
    }
    let url = queue.videos[nextIndex].url
    let service = controller?.service
    Task { [weak service] in
      _ = try? await service?.playbackStream(for: url)
    }
  }

  func prewarmNextQueueSession() {
    guard queue.isActive,
      queue.repeatMode != .one,
      let nextIndex = queue.nextIndex,
      queue.videos.indices.contains(nextIndex)
    else {
      return
    }
    prewarmer?.prewarm(queue.videos[nextIndex])
  }
}
