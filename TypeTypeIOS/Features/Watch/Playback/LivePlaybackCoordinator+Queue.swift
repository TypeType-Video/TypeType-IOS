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
    Task { @MainActor in
      if seconds > 0 {
        try? await Task.sleep(for: .seconds(seconds))
      }
      guard queue.isActive, queue.currentIndex >= 0 else { return }
      queue.currentIndex = nextIndex
      touchAndPersist()
      replacePlayback(with: queue.videos[nextIndex], autoplay: true)
    }
  }
}
