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
    let playback = LiveNativePlayback(player: player, session: session, preparation: preparation)
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
    startupTrace.mark("ready")
    if let total = startupTrace.finish(source: video.url) {
      lastStartupMilliseconds = total
      startupWatchdog?.cancel()
    }
  }

  private func nativeStateChanged(_ newState: TypeTypePlayerState, playback: LiveNativePlayback) {
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

  func fallBackFromNative(reason: String) {
    guard let playback = nativePlayback else { return }
    AppLogger.playback.error("Native playback failed, using AVPlayer: \(reason, privacy: .public)")
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
    nativePlayback?.stop()
    nativePlayback = nil
  }
}
