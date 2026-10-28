import AVFoundation
import Foundation

extension LivePlayerController {
  func loadIfNeeded() async {
    guard !didLoad else { return }
    didLoad = true
    await load()
  }

  func retry() {
    startupRetryUsed = false
    loadTask?.cancel()
    didLoad = true
    loadTask = Task { [weak self] in
      await self?.load()
    }
  }

  /// Starts playback unless the controller was stopped/closed.
  func playIfActive(rate: Float) {
    guard !isTornDown else { return }
    player.playImmediately(atRate: rate)
  }

  func playIfActive() {
    playIfActive(rate: playbackRate)
  }

  func togglePlayback() {
    presentationResumeTask?.cancel()
    presentationResumeTask = nil
    if let nativePlayback {
      providerRecoveryDesiredAutoplay = state != .playing
      if state == .playing {
        nativePlayback.player.pause()
        state = .paused
      } else {
        nativePlayback.player.play()
        if state == .paused { state = .playing }
      }
      return
    }
    if player.timeControlStatus == .playing {
      providerRecoveryDesiredAutoplay = false
      player.pause()
      // Optimistic feedback: controls update instantly, the player state
      // observer confirms or corrects afterwards.
      if state == .playing {
        state = .paused
      }
    } else {
      providerRecoveryDesiredAutoplay = true
      playIfActive()
      if state == .paused {
        state = .playing
      }
    }
  }

  func pause() {
    presentationResumeTask?.cancel()
    presentationResumeTask = nil
    providerRecoveryDesiredAutoplay = false
    player.pause()
    nativePlayback?.player.pause()
  }

  func preservePlaybackAfterViewDetach(shouldContinue: Bool) {
    presentationResumeTask?.cancel()
    guard nativePlayback == nil, shouldContinue, player.currentItem != nil else {
      self.presentationResumeTask = nil
      return
    }
    providerRecoveryDesiredAutoplay = true
    playIfActive()
    presentationResumeTask = Task { @MainActor [weak self] in
      for delay in [100, 250, 500, 900] {
        do {
          try await Task.sleep(for: .milliseconds(delay))
        } catch {
          return
        }
        guard let self, player.currentItem != nil else { return }
        if player.timeControlStatus == .paused {
          playIfActive()
        }
      }
      self?.presentationResumeTask = nil
    }
  }

  func replay() {
    if let nativePlayback {
      providerRecoveryDesiredAutoplay = true
      position = 0
      nativePlayback.seek(to: 0)
      nativePlayback.player.play()
      return
    }
    guard player.currentItem != nil else {
      retry()
      return
    }
    if preparation?.isSABR == true {
      seekSABR(to: 0, autoplay: true)
      return
    }
    providerRecoveryResumeTime = 0
    providerRecoveryDesiredAutoplay = true
    state = .loading
    player.seek(
      to: .zero,
      toleranceBefore: .zero,
      toleranceAfter: .zero
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        guard let self else { return }
        if position != 0 {
          position = 0
        }
        playIfActive()
      }
    }
  }

  func stop() {
    isTornDown = true
    pictureInPicture.cancelPendingStart()
    presentationResumeTask?.cancel()
    presentationResumeTask = nil
    sabrStallRecoveryTask?.cancel()
    sabrStallRecoveryTask = nil
    sabrRecoveryBudgetResetTask?.cancel()
    sabrRecoveryBudgetResetTask = nil
    loadTask?.cancel()
    // A closed player must not retry or install a start still in flight.
    loadGeneration += 1
    startupWatchdog?.cancel()
    startupWatchdog = nil
    startupTrace = LivePlaybackStartupTrace()
    metadataTask?.cancel()
    metadataTask = nil
    firstFrameJobs = []
    seekTask?.cancel()
    bulletCommentsTask?.cancel()
    bulletCommentsTask = nil
    providerRecoveryDesiredAutoplay = false
    player.pause()
    stopNative()
    recordHistoryIfNeeded(force: true)
    reportPlaybackSessionProgress()
    stopPlaybackSession()
    player.replaceCurrentItem(with: nil)
    playbackServer?.stop()
    playbackServer = nil
    playbackTimeOffset = 0
    if let endObservation {
      NotificationCenter.default.removeObserver(endObservation)
      self.endObservation = nil
    }
    itemObservation = nil
    playbackObservation = nil
    if let timeObserver {
      player.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }
  }

  func seek(to seconds: TimeInterval) {
    let bounded = min(max(seconds, 0), max(duration, 0))
    if let nativePlayback {
      let wasPlaying = state == .playing
      position = bounded
      nativePlayback.seek(to: bounded)
      if wasPlaying {
        // A seek can leave the in-house player reporting paused; the user
        // never asked to stop, so playback is asserted back on.
        nativePlayback.player.play()
        state = .playing
      }
      reportPlaybackSessionProgress()
      return
    }
    if preparation?.isSABR == true {
      seekSABR(to: bounded, autoplay: nil)
      return
    }
    if preparation?.providerPlayback != nil {
      providerRecoveryResumeTime = bounded
    }
    player.seek(
      to: CMTime(seconds: bounded, preferredTimescale: 600),
      toleranceBefore: .zero,
      toleranceAfter: .zero
    ) { [weak self] finished in
      guard finished else { return }
      Task { @MainActor [weak self] in
        guard let self else { return }
        let currentPosition = max(player.currentTime().seconds, 0)
        if abs(position - currentPosition) >= 0.05 {
          position = currentPosition
        }
        reportPlaybackSessionProgress()
      }
    }
  }

  func selectVideoItag(_ itag: Int?) {
    guard selectedVideoItag != itag else { return }
    selectedVideoItag = itag
    selectedVideoSourceID = availableVideoSources.first {
      $0.itag == itag
    }?.selectionID
    restartAtCurrentPosition()
  }

  func selectVideoSource(_ sourceID: String?) {
    guard selectedVideoSourceID != sourceID else { return }
    selectedVideoSourceID = sourceID
    let source = availableVideoSources.first {
      $0.selectionID == sourceID
    }
    selectedVideoItag = source.flatMap {
      $0.itag > 0 ? $0.itag : nil
    }
    restartAtCurrentPosition()
  }

  var selectedVideoResolution: Int? {
    let selectedID = selectedVideoSourceID
      ?? preparation?.video?.selectionID
    guard let selectedID,
      let source = availableVideoSources.first(where: {
        $0.selectionID == selectedID
      })
    else {
      return nil
    }
    return source.height
  }

  func selectVideoResolution(_ height: Int?) {
    guard let height else {
      selectVideoSource(nil)
      return
    }
    let candidates = availableVideoSources.filter {
      $0.height == height
    }
    guard let best = candidates.max(by: {
      ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
    }) else {
      return
    }
    selectVideoSource(best.selectionID)
  }

  func selectAudioTrack(_ trackID: String?) {
    guard selectedAudioTrackID != trackID else { return }
    selectedAudioTrackID = trackID
    selectedAudioSourceID = availableAudioSources.first {
      $0.audioTrackID == trackID
    }?.id
    restartAtCurrentPosition()
  }

  func selectAudioSource(_ sourceID: String?) {
    guard selectedAudioSourceID != sourceID else { return }
    selectedAudioSourceID = sourceID
    selectedAudioTrackID = availableAudioSources.first {
      $0.id == sourceID
    }?.audioTrackID
    restartAtCurrentPosition()
  }

  func setAudioOnly(_ enabled: Bool) {
    guard audioOnly != enabled else { return }
    audioOnly = enabled
    LiveAppPreferencesStore.shared.update {
      $0.playerAudioOnlyPlayback = enabled
    }
    restartAtCurrentPosition()
  }

  func setPlaybackRate(_ rate: Float) {
    playbackRate = Self.normalizePlaybackRate(rate)
    Self.savePlaybackRate(playbackRate)
    player.defaultRate = playbackRate
    if player.timeControlStatus == .playing {
      playIfActive(rate: playbackRate)
    }
    playbackServer?.updatePlaybackRate(playbackRate)
    nativePlayback?.setRate(playbackRate)
  }

  func flushHistory() {
    recordHistoryIfNeeded(force: true)
    reportPlaybackSessionProgress()
  }
}
