import Foundation

extension LivePlaybackCoordinator {
  func adoptCurrentScopeIfNeeded() {
    guard let scope = scopeProvider() else { return }
    if activeScope != scope {
      endRuntime(preservingPersistedQueue: true)
      queue = .empty
      activeScope = scope
      restoredScope = scope
    }
  }

  func clearQueue() {
    queue = .empty
    if let activeScope {
      queueStore.clear(activeScope)
    }
  }

  func touchAndPersist() {
    queue.updatedAt = .now
    persistQueue()
  }

  func persistQueue() {
    guard let activeScope else { return }
    guard persistenceEnabled, queue.isActive else {
      queueStore.clear(activeScope)
      return
    }
    queueStore.save(queue, for: activeScope)
  }

  func applyPersistencePolicy(enabled: Bool) {
    persistenceEnabled = enabled
    guard let activeScope else { return }
    if enabled {
      persistQueue()
    } else {
      queueStore.clear(activeScope)
    }
  }

  func endRuntime(preservingPersistedQueue: Bool) {
    cancelSleepTimer()
    if preservingPersistedQueue {
      persistQueue()
    }
    playbackGeneration += 1
    controller?.flushHistory()
    controller?.stop()
    controller = nil
    currentVideo = nil
    presentation = .hidden
  }

  func isPlayable(_ video: LiveVideoItem) -> Bool {
    !video.url.trimmingCharacters(
      in: .whitespacesAndNewlines
    ).isEmpty
  }
}
