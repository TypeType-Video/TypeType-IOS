import AVFoundation
import Foundation

extension LivePlayerController {
  func load() async {
    guard let service else {
      state = .failed(
        LivePlaybackFailure.unavailableService.localizedDescription
      )
      return
    }
    state = .loading
    loadGeneration += 1
    let generation = loadGeneration
    startupTrace.begin()
    armStartupWatchdog()
    service.preconnectMedia()
    async let audioSession: Void = configureAudioSession()
    sabrStallRecoveryTask?.cancel()
    sabrStallRecoveryTask = nil
    sabrRecoveryBudgetResetTask?.cancel()
    sabrRecoveryBudgetResetTask = nil
    sabrStallRecoveryCount = 0
    handledSponsorSegments.removeAll()
    sponsorMutedRange = nil
    do {
      async let settingsRequest = settingsService.settings()
      async let streamRequest = video.isLive
        ? service.stream(for: video.url)
        : service.playbackStream(for: video.url)
      async let progressRequest = historyService.progress(
        videoURL: video.url
      )
      settings = (try? await settingsRequest) ?? LiveSettings()
      applyLoadedSettings()
      afterFirstFrame { [weak self] in self?.loadBulletCommentsIfNeeded() }
      let loadedStream = try await streamRequest
      startupTrace.mark("stream")
      let savedPositionMS: Int64?
      do {
        savedPositionMS = try await progressRequest
      } catch {
        savedPositionMS = nil
      }
      guard !Task.isCancelled else { return }
      stream = loadedStream
      onMetadataResolved?(video.resolving(with: loadedStream))
      isLoadingFullMetadata = true
      afterFirstFrame { [weak self] in self?.loadFullMetadata(using: service) }
      if selectedVideoItag != nil {
        selectedVideoItag = nil
      }
      if selectedVideoSourceID != nil {
        selectedVideoSourceID = nil
      }
      let initial = LivePlaybackPreferences.initial(
        for: loadedStream,
        settings: settings,
        audioOnly: audioOnly,
        preferredCodec: appPreferences.preferences.playerPreferredCodec
      )
      if selectedAudioTrackID != initial.audioTrackID {
        selectedAudioTrackID = initial.audioTrackID
      }
      if selectedAudioSourceID != initial.audioSourceID {
        selectedAudioSourceID = initial.audioSourceID
      }
      var preparation = try service.prepare(
        stream: loadedStream,
        sourceURL: video.url,
        preferences: preferences
      )
      if let savedPositionMS, savedPositionMS > 0 {
        preparation = preparation.resuming(
          at: TimeInterval(savedPositionMS) / 1_000
        )
      }
      resetProviderRecoveryState(
        for: preparation,
        autoplay: initialAutoplay
      )
      await audioSession
      startupTrace.mark("audio")
      guard generation == loadGeneration else { return }
      try await installWithProviderFallback(
        preparation,
        autoplay: initialAutoplay,
        seekOverride: nil
      )
    } catch is CancellationError {
      return
    } catch {
      Self.logPreparationFailure(error)
      if Self.isTransientStartupFailure(error),
        retryStartupOnce(reason: "\(error)") {
        return
      }
      startupWatchdog?.cancel()
      state = .failed(Self.message(for: error))
      stopPlaybackSession()
    }
  }

  func restartAtCurrentPosition(autoplay: Bool? = nil) {
    guard let service, let stream else { return }
    let restartTime = position
    let wasPlaying = autoplay ?? nativePlayback.map { $0.player.state == .playing } ?? (player.timeControlStatus == .playing)
    state = .loading
    loadGeneration += 1
    loadTask?.cancel()
    loadTask = Task { [weak self] in
      guard let self else { return }
      do {
        let preparation = try service.prepare(
          stream: stream,
          sourceURL: video.url,
          preferences: preferences
        )
        guard !Task.isCancelled else { return }
        resetProviderRecoveryState(
          for: preparation,
          autoplay: wasPlaying
        )
        try await installWithProviderFallback(
          preparation,
          autoplay: wasPlaying,
          seekOverride: restartTime
        )
      } catch {
        Self.logPreparationFailure(error)
        if abandonAirPlayHandoff(reason: String(describing: error)) { return }
        state = .failed(Self.message(for: error))
        stopPlaybackSession()
      }
    }
  }

  var preferences: LivePlaybackPreferences {
    LivePlaybackPreferences(
      quality: settings.defaultQuality,
      preferredCodec: appPreferences.preferences
        .playerPreferredCodec,
      videoItag: selectedVideoItag,
      videoSourceID: selectedVideoSourceID,
      audioTrackID: selectedAudioTrackID,
      audioSourceID: selectedAudioSourceID,
      audioOnly: audioOnly
    )
  }

  func install(
    _ preparation: LivePlaybackPreparation,
    autoplay: Bool,
    seekOverride: TimeInterval?
  ) async throws {
    startupTrace.mark("prepared")
    let generation = loadGeneration
    player.pause()
    stopNative()
    playbackServer?.stop()
    playbackServer = nil
    let resolvedDuration = TimeInterval(preparation.stream.duration)
    if duration != resolvedDuration {
      duration = resolvedDuration
    }
    let requestedTime = LivePlaybackPreparation.startTime(
      requested: seekOverride ?? preparation.resumeTime,
      duration: duration
    )
    let installedPreparation = preparation.isSABR
      ? preparation.resuming(at: requestedTime)
      : preparation
    self.preparation = installedPreparation
    pendingSeek = installedPreparation.isSABR ? nil : requestedTime
    playbackTimeOffset = 0
    if playsNatively(installedPreparation), let service {
      do {
        try await installNative(
          installedPreparation,
          service: service,
          startTime: requestedTime,
          autoplay: autoplay,
          generation: generation
        )
        return
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        AppLogger.playback.error("Native playback unavailable, using AVPlayer: \(String(describing: error), privacy: .public)")
        nativeFallbackUsed = true
      }
    }

    let assetURL: URL
    if installedPreparation.usesAuthenticatedLoader,
      let service {
      let server = LivePlaybackHTTPServer(
        service: service,
        preparation: installedPreparation,
        preferredSubtitleLanguage: settings.defaultSubtitleLanguage,
        host: playbackServerHost,
        providerFailureHandler: { [weak self] server, kind in
          Task { @MainActor [weak self] in
            self?.recoverProviderPlayback(
              reportedBy: server,
              failedKind: kind
            )
          }
        },
        sabrFailureHandler: { [weak self] error in
          Task { @MainActor [weak self] in
            guard let self else { return }
            sabrStallRecoveryTask?.cancel()
            sabrRecoveryBudgetResetTask?.cancel()
            state = .failed(Self.message(for: error))
            stopPlaybackSession()
          }
        }
      )
      do {
        assetURL = try await server.start()
      } catch {
        server.stop()
        throw error
      }
      guard generation == loadGeneration else {
        server.stop()
        throw CancellationError()
      }
      playbackServer = server
      startupTrace.mark("session")
      if installedPreparation.isSABR {
        server.updatePlaybackRate(playbackRate)
        playbackTimeOffset = server.sabrPlaybackStartTime
        if position != playbackTimeOffset {
          position = playbackTimeOffset
        }
      }
    } else {
      guard let preparedURL = installedPreparation.assetURL else {
        throw LivePlaybackFailure.invalidServerResource
      }
      assetURL = preparedURL
    }
    installPlayerItem(at: assetURL, autoplay: autoplay)
  }

  func installPlayerItem(
    at assetURL: URL,
    autoplay: Bool
  ) {
    startupTrace.mark("item")
    let asset = AVURLAsset(url: assetURL)
    installPlayerItem(asset: asset, autoplay: autoplay)
  }

  func installPlayerItem(
    asset: AVAsset,
    autoplay: Bool
  ) {
    let item = AVPlayerItem(asset: asset)
    let isLive = preparation?.stream.isLive == true
    item.preferredForwardBufferDuration = isLive
      ? TimeInterval(LiveSABRBufferPolicy.liveGoalMS) / 1_000
      : 20
    if isLive {
      item.automaticallyPreservesTimeOffsetFromLive = true
    }
    observe(item, autoplay: autoplay)
    guard !isTornDown else { return }
    player.replaceCurrentItem(with: item)
    player.defaultRate = playbackRate
  // Do not reconfigure the audio session here: on the main thread it trips the unresponsiveness warnings.
  }
}
