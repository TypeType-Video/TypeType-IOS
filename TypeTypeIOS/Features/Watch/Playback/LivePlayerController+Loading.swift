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
    handledSponsorSegments.removeAll()
    sponsorMutedRange = nil
    do {
      async let settingsRequest = settingsService.settings()
      async let streamRequest = service.stream(for: video.url)
      async let progressRequest = historyService.progress(
        videoURL: video.url
      )
      settings = (try? await settingsRequest) ?? LiveSettings()
      applyLoadedSettings()
      loadBulletCommentsIfNeeded()
      let loadedStream = try await streamRequest
      let savedPositionMS: Int64?
      do {
        savedPositionMS = try await progressRequest
      } catch {
        savedPositionMS = nil
      }
      guard !Task.isCancelled else { return }
      stream = loadedStream
      onMetadataResolved?(video.resolving(with: loadedStream))
      if selectedVideoItag != nil {
        selectedVideoItag = nil
      }
      if selectedVideoSourceID != nil {
        selectedVideoSourceID = nil
      }
      let preferredAudioTrackID = settings.defaultAudioLanguage.isEmpty
        ? nil
        : loadedStream.audioStreams.first(where: {
          $0.audioLocale?.lowercased().hasPrefix(
            settings.defaultAudioLanguage.lowercased()
          ) == true
        })?.audioTrackID
      if selectedAudioTrackID != preferredAudioTrackID {
        selectedAudioTrackID = preferredAudioTrackID
      }
      let preferredAudioSourceID = loadedStream.audioStreams.first(where: {
        guard !settings.defaultAudioLanguage.isEmpty else { return false }
        return $0.audioLocale?.lowercased().hasPrefix(
          settings.defaultAudioLanguage.lowercased()
        ) == true
      })?.id
      if selectedAudioSourceID != preferredAudioSourceID {
        selectedAudioSourceID = preferredAudioSourceID
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
      try await installWithProviderFallback(
        preparation,
        autoplay: initialAutoplay,
        seekOverride: nil
      )
    } catch is CancellationError {
      return
    } catch {
      Self.logPreparationFailure(error)
      state = .failed(Self.message(for: error))
      stopPlaybackSession()
    }
  }

  func restartAtCurrentPosition() {
    guard let service, let stream else { return }
    let restartTime = position
    let wasPlaying = player.timeControlStatus == .playing
    state = .loading
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
        state = .failed(Self.message(for: error))
        stopPlaybackSession()
      }
    }
  }

  var preferences: LivePlaybackPreferences {
    LivePlaybackPreferences(
      quality: settings.defaultQuality,
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
    player.pause()
    playbackServer?.stop()
    playbackServer = nil
    let resolvedDuration = TimeInterval(preparation.stream.duration)
    if duration != resolvedDuration {
      duration = resolvedDuration
    }
    let requestedTime: TimeInterval = {
      let requested = seekOverride ?? preparation.resumeTime
      guard duration > 0, requested < duration - 5 else { return 0 }
      return max(requested, 0)
    }()
    let installedPreparation = preparation.isSABR
      ? preparation.resuming(at: requestedTime)
      : preparation
    self.preparation = installedPreparation
    pendingSeek = installedPreparation.isSABR ? nil : requestedTime
    playbackTimeOffset = 0

    let assetURL: URL
    if installedPreparation.usesAuthenticatedLoader,
      let service {
      let server = LivePlaybackHTTPServer(
        service: service,
        preparation: installedPreparation,
        preferredSubtitleLanguage: settings.defaultSubtitleLanguage,
        providerFailureHandler: { [weak self] server, kind in
          Task { @MainActor [weak self] in
            self?.recoverProviderPlayback(
              reportedBy: server,
              failedKind: kind
            )
          }
        }
      )
      do {
        assetURL = try await server.start()
      } catch {
        server.stop()
        throw error
      }
      playbackServer = server
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
    let asset = AVURLAsset(url: assetURL)
    installPlayerItem(asset: asset, autoplay: autoplay)
  }

  func installPlayerItem(
    asset: AVAsset,
    autoplay: Bool
  ) {
    let item = AVPlayerItem(asset: asset)
    item.preferredForwardBufferDuration = 20
    observe(item, autoplay: autoplay)
    player.replaceCurrentItem(with: item)
    player.defaultRate = playbackRate
    do {
      try DemoAudioSessionConfigurator.configure(
        backgroundAudio: true
      )
    } catch {
      state = .failed("The audio session could not be configured.")
    }
  }
}
