import Foundation

extension LivePlayerController {
  var supportsBulletComments: Bool {
    guard let host = URL(string: video.url)?.host?.lowercased() else {
      return false
    }
    return host == "nicovideo.jp"
      || host.hasSuffix(".nicovideo.jp")
      || host == "nico.ms"
  }

  var precisePosition: TimeInterval {
    let current = nativePlayback?.player.currentTime ?? player.currentTime().seconds
    guard current.isFinite else { return position }
    return Self.timelinePosition(
      playbackSeconds: current,
      offset: playbackTimeOffset,
      duration: duration
    )
  }

  func loadBulletCommentsIfNeeded() {
    bulletCommentsTask?.cancel()
    bulletCommentsLoadGeneration += 1
    let generation = bulletCommentsLoadGeneration
    guard supportsBulletComments, bulletCommentsEnabled,
      !settings.hideComments,
      let service
    else {
      scheduleBulletCommentState(.empty, generation: generation)
      return
    }
    bulletCommentsTask = Task { @MainActor [weak self] in
      guard let self else { return }
      guard !Task.isCancelled,
        bulletCommentsLoadGeneration == generation
      else {
        return
      }
      scheduleBulletCommentState(.loading, generation: generation)

      let loadedComments: [LiveBulletComment]
      do {
        loadedComments = try await service.bulletComments(
          for: video.url
        )
      } catch is CancellationError {
        return
      } catch {
        loadedComments = []
      }

      guard !Task.isCancelled,
        bulletCommentsLoadGeneration == generation
      else {
        return
      }
      scheduleBulletCommentState(
        LiveBulletCommentState(
          comments: loadedComments.sorted {
            $0.durationMilliseconds < $1.durationMilliseconds
          },
          isLoading: false
        ),
        generation: generation
      )
    }
  }

  private func scheduleBulletCommentState(
    _ state: LiveBulletCommentState,
    generation: Int
  ) {
    bulletCommentStateRevision += 1
    let revision = bulletCommentStateRevision
    let delay: DispatchTimeInterval = if state.isLoading {
      .milliseconds(250)
    } else if state.comments.isEmpty {
      .milliseconds(20)
    } else {
      .milliseconds(100)
    }
    DispatchQueue.main.asyncAfter(
      deadline: .now() + delay
    ) { [weak self] in
      guard let self,
        bulletCommentsLoadGeneration == generation,
        bulletCommentStateRevision == revision,
        bulletCommentStore.state != state
      else {
        return
      }
      bulletCommentStore.update(state)
    }
  }

  func setBulletCommentsEnabled(_ enabled: Bool) {
    bulletCommentsEnabled = enabled
    UserDefaults.standard.set(
      enabled,
      forKey: Self.bulletCommentsEnabledKey
    )
    loadBulletCommentsIfNeeded()
  }

  func setBulletCommentSpeed(_ value: Double) {
    bulletCommentSpeed = min(max(value, 0.5), 2)
    UserDefaults.standard.set(
      bulletCommentSpeed,
      forKey: Self.bulletCommentSpeedKey
    )
  }

  func setBulletCommentSize(_ value: Double) {
    bulletCommentSize = min(max(value, 0.5), 2)
    UserDefaults.standard.set(
      bulletCommentSize,
      forKey: Self.bulletCommentSizeKey
    )
  }

  static let bulletCommentsEnabledKey =
    "typetype.player.danmaku.enabled"
  static let bulletCommentSpeedKey =
    "typetype.player.danmaku.speed"
  static let bulletCommentSizeKey =
    "typetype.player.danmaku.size"
}
