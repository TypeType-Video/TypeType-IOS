import Foundation

extension LivePlaybackCoordinator {
  func expand() {
    guard hasActivePlayback else { return }
    presentation = .expanded
  }

  func minimize() {
    guard hasActivePlayback else { return }
    guard controller?.state == .playing || controller?.state == .paused
    else {
      close()
      return
    }
    controller?.flushHistory()
    startSystemPictureInPicture()
    presentation = .mini
  }

  func startSystemPictureInPicture() {
    guard let controller else { return }
    // Audio-only has no video layer: the PiP window would come up empty and without its close button.
    guard !controller.audioOnly else { return }
    let posterURL = currentVideo?.thumbnail
    controller.pictureInPicture.onChange = { [weak self] in
      self?.objectWillChange.send()
    }
    // The placeholder goes in the layer before the start: the system refuses PiP on an empty layer.
    Task { [weak self] in
      guard let self else { return }
      await controller.pictureInPicture.loadPoster(url: posterURL)
      controller.pictureInPicture.start(
        onRestore: { [weak self] in self?.expand() },
        onClose: { [weak self] in self?.close() }
      )
    }
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
    controller?.retryAfterNetworkRecovery()
  }

  func replacePlayback(
    with video: LiveVideoItem,
    autoplay: Bool,
    offline: LiveOfflinePlaybackItem? = nil
  ) {
    playbackGeneration += 1
    let generation = playbackGeneration
    controller?.pictureInPicture.bringInline()
    controller?.stop()
    prewarmNextQueueEntry()
    let next = playerFactory(video, autoplay)
    next.onPlaybackEnded = { [weak self, weak next] in
      guard let self, self.controller === next,
        self.playbackGeneration == generation
      else {
        return
      }
      self.handlePlaybackEnded()
    }
    next.onNearEnd = { [weak self, weak next] in
      guard let self, self.controller === next,
        self.playbackGeneration == generation
      else {
        return
      }
      self.prewarmNextQueueSession()
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
    if let offline {
      Task { await next.installOffline(stream: offline.watchStream, fileURL: offline.fileURL) }
    } else {
      Task { await next.loadIfNeeded() }
    }
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
