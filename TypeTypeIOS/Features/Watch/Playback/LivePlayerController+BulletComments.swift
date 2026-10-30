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
    appPreferences.update { $0.danmakuEnabled = enabled }
  }

  func setBulletCommentSpeed(_ value: Double) {
    appPreferences.update { $0.danmakuSpeed = min(max(value, 0.5), 2) }
  }

  func setBulletCommentSize(_ value: Double) {
    appPreferences.update { $0.danmakuSize = min(max(value, 0.5), 2) }
  }

  func observeBulletCommentPreferences() {
    bulletCommentPreferencesObservation = appPreferences.$preferences
      .sink { [weak self] preferences in
        self?.applyBulletCommentPreferences(preferences)
      }
  }

  private func applyBulletCommentPreferences(_ preferences: LiveAppPreferences) {
    bulletCommentSpeed = min(max(preferences.danmakuSpeed, 0.5), 2)
    bulletCommentSize = min(max(preferences.danmakuSize, 0.5), 2)
    guard bulletCommentsEnabled != preferences.danmakuEnabled else { return }
    bulletCommentsEnabled = preferences.danmakuEnabled
    loadBulletCommentsIfNeeded()
  }

  static func moveLegacyBulletCommentChoices(
    into store: LiveAppPreferencesStore,
    from defaults: UserDefaults
  ) {
    let keys = ["typetype.player.danmaku.enabled", "typetype.player.danmaku.speed", "typetype.player.danmaku.size"]
    guard keys.contains(where: { defaults.object(forKey: $0) != nil }) else { return }
    store.update { preferences in
      if defaults.object(forKey: keys[0]) != nil {
        preferences.danmakuEnabled = defaults.bool(forKey: keys[0])
      }
      if defaults.object(forKey: keys[1]) != nil {
        preferences.danmakuSpeed = defaults.double(forKey: keys[1])
      }
      if defaults.object(forKey: keys[2]) != nil {
        preferences.danmakuSize = defaults.double(forKey: keys[2])
      }
    }
    keys.forEach(defaults.removeObject(forKey:))
  }
}
