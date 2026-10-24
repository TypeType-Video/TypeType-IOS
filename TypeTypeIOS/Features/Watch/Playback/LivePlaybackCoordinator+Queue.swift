import Foundation

extension LivePlaybackCoordinator {
  func play(index: Int) {
    guard queue.isActive, queue.videos.indices.contains(index) else {
      return
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
    guard queue.isActive else { return }
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
    let skipDelay =
      controller?.settings.skipPlaylistAutoplayScreen == true
    let seconds = skipDelay
      ? 0
      : LiveAppPreferencesStore.shared.preferences
        .playerAutoplayCountdownSeconds
    guard seconds > 0 else {
      commitAutoplayAdvance(to: nextIndex)
      return
    }
    pendingAutoplayIndex = nextIndex
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
      self.commitAutoplayAdvance(to: nextIndex)
    }
  }

  func skipAutoplayCountdown() {
    guard let index = pendingAutoplayIndex else { return }
    commitAutoplayAdvance(to: index)
  }

  func cancelAutoplayCountdown() {
    autoplayCountdownTask?.cancel()
    autoplayCountdownTask = nil
    pendingAutoplayIndex = nil
    autoplayCountdownRemaining = nil
  }

  private func commitAutoplayAdvance(to index: Int) {
    autoplayCountdownTask?.cancel()
    autoplayCountdownTask = nil
    pendingAutoplayIndex = nil
    autoplayCountdownRemaining = nil
    guard queue.isActive, queue.videos.indices.contains(index) else {
      return
    }
    queue.currentIndex = index
    touchAndPersist()
    replacePlayback(with: queue.videos[index], autoplay: true)
  }
}

extension LivePlaybackCoordinator {
  /// Warms the next queue entry's stream metadata so advancing (autoplay or
  /// manual) starts without the fetch round trip.
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
      _ = try? await service?.stream(for: url)
    }
  }
}
