import Foundation
import TypeTypePlayerKit

extension LivePlayerController {
  static let nativePlaybackKey = "typetype.player.native"

  func playsNatively(_ preparation: LivePlaybackPreparation) -> Bool {
    guard !preparation.stream.isLive,
      !nativeFallbackUsed,
      UserDefaults.standard.object(forKey: Self.nativePlaybackKey) as? Bool ?? true
    else {
      return false
    }
    if preparation.isSABR { return true }
    if case .separateProgressive? = preparation.providerPlayback { return true }
    return false
  }

  func installNative(
    _ preparation: LivePlaybackPreparation,
    service: LivePlaybackServiceProtocol,
    startTime: TimeInterval,
    autoplay: Bool,
    generation: Int
  ) async throws {
    let (source, session) = try await nativeSource(for: preparation, service: service, generation: generation)
    startupTrace.mark("session")
    let player = TypeTypePlayer(source: source)
    let pictureInPicture = LiveNativePictureInPictureSource(
      setPlaying: { [weak self] playing in
        Task { @MainActor [weak self] in self?.setNativePlaying(playing) }
      },
      skip: { [weak self] seconds in
        Task { @MainActor [weak self] in
          guard let self else { return }
          seek(to: position + seconds)
        }
      }
    )
    let playback = LiveNativePlayback(
      player: player,
      session: session,
      preparation: preparation,
      pictureInPictureSource: pictureInPicture
    )
    player.onStart = { [weak self, weak playback] in
      guard let self, let playback, nativePlayback === playback else { return }
      nativeDidStart(playback)
    }
    player.onStateChange = { [weak self, weak playback] newState in
      guard let self, let playback, nativePlayback === playback else { return }
      nativeStateChanged(newState, playback: playback)
    }
    player.onTime = { [weak self, weak playback] time in
      guard let self, let playback, nativePlayback === playback else { return }
      handleTimeTick(time)
    }
    player.isMuted = muted || sponsorMutedRange != nil
    player.volume = Float(min(max(settings.volume, 0), 1))
    nativePlayback = playback
    playback.setRate(playbackRate)
    playbackTimeOffset = 0
    position = startTime
    startupTrace.mark("item")
    player.start(at: startTime, autoplay: autoplay)
  }

  private func nativeSource(
    for preparation: LivePlaybackPreparation,
    service: LivePlaybackServiceProtocol,
    generation: Int
  ) async throws -> (MediaSegmentSource, LiveSABRPlaybackSession?) {
    guard preparation.isSABR else {
      guard let source = LiveProviderSegmentSource(preparation: preparation, service: service) else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      return (source, nil)
    }
    let session = LiveSABRPlaybackSession(
      service: service,
      preparation: preparation,
      maintenanceFailureHandler: { [weak self] error in
        Task { @MainActor [weak self] in
          self?.fallBackFromNative(reason: String(describing: error))
        }
      }
    )
    let snapshot = try await session.start()
    guard generation == loadGeneration, snapshot.isIndexedVOD else {
      await session.stopMaintenance()
      throw generation == loadGeneration ? LivePlaybackFailure.invalidSABRContract : CancellationError()
    }
    let source = LiveSABRSegmentSource(session: session, service: service, audioOnly: preparation.audioOnly)
    return (source, session)
  }

  private func nativeDidStart(_ playback: LiveNativePlayback) {
    playback.hasStarted = true
    playback.nowPlaying.activate(
      title: stream?.title ?? video.title,
      artist: stream?.uploaderName ?? video.uploaderName,
      duration: duration,
      artworkURL: video.thumbnail,
      commands: LiveNowPlaying.Commands(
        play: { [weak self] in self?.setNativePlaying(true) },
        pause: { [weak self] in self?.setNativePlaying(false) },
        seek: { [weak self] time in self?.seek(to: time) },
        skip: { [weak self] seconds in
          guard let self else { return }
          seek(to: position + seconds)
        }
      )
    )
    startupTrace.mark("ready")
    reloadNativeSubtitles()
    if let total = startupTrace.finish(source: video.url) {
      lastStartupMilliseconds = total
      startupWatchdog?.cancel()
    }
  }

  private func setNativePlaying(_ playing: Bool) {
    AppLogger.playback
      .info("native setPlaying=\(playing, privacy: .public) state=\(String(describing: self.state), privacy: .public)")
    guard nativePlayback != nil, playing != (state == .playing) else { return }
    togglePlayback()
  }

  private func nativeStateChanged(_ newState: TypeTypePlayerState, playback: LiveNativePlayback) {
    defer {
      playback.pictureInPictureSource.update(duration: duration, paused: state != .playing)
      pictureInPicture.invalidatePlaybackState()
      playback.nowPlaying.update(
        elapsed: playback.player.currentTime,
        rate: state == .playing ? playbackRate : 0,
        duration: duration
      )
    }
    switch newState {
    case .idle:
      break
    case .buffering:
      if state != .loading { state = .loading }
    case .playing:
      if state != .playing { state = .playing }
      startPlaybackSessionIfNeeded()
    case .paused:
      let paused: State = playback.hasStarted ? .paused : .ready
      if state != paused { state = paused }
    case .ended:
      nativePlaybackEnded()
    case let .failed(reason):
      fallBackFromNative(reason: reason)
    }
  }

  private func nativePlaybackEnded() {
    state = .paused
    recordHistoryIfNeeded(force: true)
    reportPlaybackSessionProgress()
    stopPlaybackSession()
    if loopsPlayback {
      replay()
    } else {
      onPlaybackEnded?()
    }
  }

  /// Presents beta's landscape-forced host: the presented controller's
  /// orientations override the user's rotation lock, which a plain window
  /// rotation request cannot. The host clears the flag on dismissal.
  func enterNativeFullscreen() {
    guard !isPresentingFullscreen else { return }
    LiveLandscapeHostingController.present(for: self)
  }

  func exitNativeFullscreen() {
    LiveLandscapeHostingController.dismissActive()
  }

  func fallBackFromNative(reason: String) {
    guard let playback = nativePlayback else { return }
    AppLogger.playback.error(
      "Native playback failed in fullscreen=\(self.isPresentingFullscreen, privacy: .public), using AVPlayer: \(reason, privacy: .public)"
    )

    let resumeAt = playback.hasStarted ? position : playback.preparation.resumeTime
    let autoplay = providerRecoveryDesiredAutoplay || state == .playing || !playback.hasStarted
    playback.stop()
    nativePlayback = nil
    nativeFallbackUsed = true
    state = .loading
    loadTask?.cancel()
    loadTask = Task { [weak self] in
      guard let self else { return }
      do {
        try await install(playback.preparation, autoplay: autoplay, seekOverride: resumeAt)
      } catch is CancellationError {
        return
      } catch {
        state = .failed(Self.message(for: error))
        stopPlaybackSession()
      }
    }
  }

  func stopNative() {
    nativeSubtitlesTask?.cancel()
    nativeSubtitlesTask = nil
    if !nativeSubtitleCues.isEmpty { nativeSubtitleCues = [] }
    nativePlayback?.stop()
    nativePlayback = nil
  }
}
