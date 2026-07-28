import Foundation

extension LivePlaybackCoordinator {
  func expand() {
    guard hasActivePlayback else { return }
    presentation = .expanded
  }

  func minimize() {
    guard hasActivePlayback else { return }
    controller?.flushHistory()
    presentation = .mini
  }

  func close() {
    clearQueue()
    endRuntime(preservingPersistedQueue: false)
  }

  func endSession() {
    endRuntime(preservingPersistedQueue: true)
    queue = .empty
    activeScope = nil
    restoredScope = nil
    persistenceEnabled = false
  }

  func forgetServer(_ serverID: String) {
    if activeScope?.serverID == serverID {
      endRuntime(preservingPersistedQueue: false)
      queue = .empty
      activeScope = nil
      restoredScope = nil
      persistenceEnabled = false
    }
    queueStore.clear(serverID: serverID)
  }

  func applySettings(_ settings: LiveSettings) {
    applyPersistencePolicy(enabled: !settings.disableWatchHistory)
    controller?.applySettings(settings)
  }

  func retryAfterNetworkRecovery() {
    guard let controller,
      case .failed = controller.state
    else {
      return
    }
    controller.retry()
  }

  func replacePlayback(
    with video: LiveVideoItem,
    autoplay: Bool
  ) {
    playbackGeneration += 1
    let generation = playbackGeneration
    controller?.stop()
    let next = playerFactory(video, autoplay)
    next.onPlaybackEnded = { [weak self, weak next] in
      guard let self, self.controller === next,
        self.playbackGeneration == generation
      else {
        return
      }
      self.handlePlaybackEnded()
    }
    next.onMetadataResolved = { [weak self, weak next] resolved in
      guard let self, self.controller === next,
        self.playbackGeneration == generation
      else {
        return
      }
      self.acceptResolvedMetadata(resolved)
    }
    currentVideo = video
    controller = next
    Task { await next.loadIfNeeded() }
  }

  func acceptResolvedMetadata(_ video: LiveVideoItem) {
    currentVideo = video
    guard queue.isActive,
      queue.videos.indices.contains(queue.currentIndex),
      queue.videos[queue.currentIndex].url == video.url
    else {
      return
    }
    queue.videos[queue.currentIndex] = video
    touchAndPersist()
  }
}
