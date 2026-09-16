import AVFoundation
import Foundation

extension LivePlayerController {
  func loadIfNeeded() async {
    guard !didLoad else { return }
    didLoad = true
    await load()
  }

  func retry() {
    loadTask?.cancel()
    didLoad = true
    loadTask = Task { [weak self] in
      await self?.load()
    }
  }

  func togglePlayback() {
    presentationResumeTask?.cancel()
    presentationResumeTask = nil
    if player.timeControlStatus == .playing {
      providerRecoveryDesiredAutoplay = false
      player.pause()
    } else {
      providerRecoveryDesiredAutoplay = true
      player.playImmediately(atRate: playbackRate)
    }
  }

  func pause() {
    presentationResumeTask?.cancel()
    presentationResumeTask = nil
    providerRecoveryDesiredAutoplay = false
    player.pause()
  }

  func preservePlaybackAfterViewDetach(shouldContinue: Bool) {
    presentationResumeTask?.cancel()
    guard shouldContinue, player.currentItem != nil else {
      self.presentationResumeTask = nil
      return
    }
    providerRecoveryDesiredAutoplay = true
    player.playImmediately(atRate: playbackRate)
    presentationResumeTask = Task { @MainActor [weak self] in
      for delay in [100, 250, 500, 900] {
        do {
          try await Task.sleep(for: .milliseconds(delay))
        } catch {
          return
        }
        guard let self, player.currentItem != nil else { return }
        if player.timeControlStatus == .paused {
          player.playImmediately(atRate: playbackRate)
        }
      }
      self?.presentationResumeTask = nil
    }
  }

  func replay() {
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
        try? await Task.sleep(for: .milliseconds(100))
        guard let self else { return }
        if position != 0 {
          position = 0
        }
        player.playImmediately(atRate: playbackRate)
      }
    }
  }

  func stop() {
    presentationResumeTask?.cancel()
    presentationResumeTask = nil
    sabrStallRecoveryTask?.cancel()
    sabrStallRecoveryTask = nil
    sabrRecoveryBudgetResetTask?.cancel()
    sabrRecoveryBudgetResetTask = nil
    loadTask?.cancel()
    seekTask?.cancel()
    bulletCommentsTask?.cancel()
    bulletCommentsTask = nil
    providerRecoveryDesiredAutoplay = false
    player.pause()
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
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(100))
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
    restartAtCurrentPosition()
  }

  func setPlaybackRate(_ rate: Float) {
    playbackRate = Self.normalizePlaybackRate(rate)
    Self.savePlaybackRate(playbackRate)
    player.defaultRate = playbackRate
    if player.timeControlStatus == .playing {
      player.rate = playbackRate
    }
    playbackServer?.updatePlaybackRate(playbackRate)
  }

  func flushHistory() {
    recordHistoryIfNeeded(force: true)
    reportPlaybackSessionProgress()
  }
}
