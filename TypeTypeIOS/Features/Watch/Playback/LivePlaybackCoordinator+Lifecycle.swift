import Foundation

extension LivePlaybackCoordinator {
  func expand() {
    guard hasActivePlayback else { return }
    presentation = .expanded
  }

  func minimize() {
    guard hasActivePlayback else { return }
    // Closing before playback ever started means "drop it": no PiP, no
    // audio, no card. The mini player only carries playback that ran.
    guard controller?.state == .playing || controller?.state == .paused
    else {
      close()
      return
    }
    controller?.flushHistory()
    // Twitch-style: float the real system PiP window over the app. When PiP
    // is unavailable or fails, isEngaged stays false and the in-app card
    // shows instead.
    startSystemPictureInPicture()
    presentation = .mini
  }

  /// Starts the system PiP window for the current playback. The content
  /// layer was installed into the live player view by LivePlayerLayerView.
  func startSystemPictureInPicture() {
    guard let controller else { return }
    let posterURL = currentVideo?.thumbnail
    controller.pictureInPicture.onChange = { [weak self] in
      self?.objectWillChange.send()
    }
    // The placeholder must be in the layer BEFORE the start: the system
    // refuses a PiP window backed by an empty layer (that is what made the
    // window only appear once the video rendered).
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
    autoplay: Bool
  ) {
    playbackGeneration += 1
    let generation = playbackGeneration
    // A new video must not stack on a running PiP window (two scenes and
    // two streams): close the old window silently, playback is replaced.
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
