import AVFoundation
import Foundation

extension LivePlayerController {
  func resetProviderRecoveryState(
    for preparation: LivePlaybackPreparation,
    autoplay: Bool
  ) {
    attemptedProviderVideoSourceIDs.removeAll()
    attemptedProviderAudioSourceIDs.removeAll()
    providerRecoveryInProgress = false
    providerRecoveryResumeTime = max(preparation.resumeTime, 0)
    providerRecoveryDesiredAutoplay = autoplay
    if preparation.providerPlayback != nil {
      if let sourceID = preparation.video?.selectionID {
        attemptedProviderVideoSourceIDs.insert(sourceID)
      }
      if let sourceID = preparation.audio?.id {
        attemptedProviderAudioSourceIDs.insert(sourceID)
      }
    }
  }

  func installWithProviderFallback(
    _ initialPreparation: LivePlaybackPreparation,
    autoplay: Bool,
    seekOverride: TimeInterval?
  ) async throws {
    var candidate = initialPreparation
    while true {
      do {
        try await install(
          candidate,
          autoplay: autoplay,
          seekOverride: seekOverride
        )
        return
      } catch {
        guard candidate.providerPlayback != nil,
          let fallback = nextProviderVideoSource()
        else {
          throw error
        }
        selectedVideoItag = nil
        selectedVideoSourceID = fallback.selectionID
        attemptedProviderVideoSourceIDs.insert(fallback.selectionID)
        AppLogger.app.info(
          "Provider startup probe selected \(fallback.displayName, privacy: .public) after an unreadable source."
        )
        guard let service, let stream else {
          throw error
        }
        candidate = try service.prepare(
          stream: stream,
          sourceURL: video.url,
          preferences: preferences
        )
      }
    }
  }

  func recoverProviderPlayback(
    reportedBy server: LivePlaybackHTTPServer,
    failedKind: LivePlaybackHTTPServer.ProviderMediaKind
  ) {
    guard playbackServer === server,
      !providerRecoveryInProgress,
      let service,
      let stream,
      preparation?.providerPlayback != nil
    else {
      return
    }

    let recoveredSource: String
    switch failedKind {
    case .video:
      guard let source = nextProviderVideoSource() else {
        failProviderRecovery()
        return
      }
      selectedVideoItag = nil
      selectedVideoSourceID = source.selectionID
      attemptedProviderVideoSourceIDs.insert(source.selectionID)
      recoveredSource = source.displayName
    case .audio:
      guard let source = nextProviderAudioSource() else {
        failProviderRecovery()
        return
      }
      selectedAudioSourceID = source.id
      attemptedProviderAudioSourceIDs.insert(source.id)
      recoveredSource = source.displayName
    }

    let restartTime = max(position, providerRecoveryResumeTime, 0)
    providerRecoveryResumeTime = restartTime
    let shouldAutoplay = providerRecoveryDesiredAutoplay
    providerRecoveryInProgress = true
    state = .loading
    AppLogger.app.info(
      "Recovering provider playback at \(restartTime, privacy: .public)s with \(recoveredSource, privacy: .public)."
    )

    loadTask?.cancel()
    loadTask = Task { [weak self] in
      guard let self else { return }
      do {
        let recoveredPreparation = try service.prepare(
          stream: stream,
          sourceURL: video.url,
          preferences: preferences
        )
        guard !Task.isCancelled else { return }
        try await installWithProviderFallback(
          recoveredPreparation,
          autoplay: shouldAutoplay,
          seekOverride: restartTime
        )
        providerRecoveryInProgress = false
      } catch is CancellationError {
        providerRecoveryInProgress = false
      } catch {
        providerRecoveryInProgress = false
        Self.logPreparationFailure(error)
        state = .failed(Self.message(for: error))
        stopPlaybackSession()
      }
    }
  }

  private func nextProviderVideoSource()
    -> LivePlaybackVideoSource? {
    let current = preparation?.video
    let candidates = availableVideoSources.filter {
      !$0.isSABR
        && !attemptedProviderVideoSourceIDs.contains($0.selectionID)
    }
    guard !candidates.isEmpty else { return nil }
    guard let current else {
      return candidates.max(by: Self.providerVideoAscending)
    }
    let noHigherThanCurrent = candidates.filter {
      $0.height < current.height
        || ($0.height == current.height
          && ($0.bitrate ?? 0) < (current.bitrate ?? 0))
    }
    return (noHigherThanCurrent.isEmpty ? candidates : noHigherThanCurrent)
      .max(by: Self.providerVideoAscending)
  }

  private func nextProviderAudioSource()
    -> LivePlaybackAudioSource? {
    let currentTrackID = preparation?.audio?.audioTrackID
    let candidates = availableAudioSources.filter {
      !$0.isSABR
        && !attemptedProviderAudioSourceIDs.contains($0.id)
    }
    let matchingTrack = candidates.filter {
      $0.audioTrackID == currentTrackID
    }
    return (matchingTrack.isEmpty ? candidates : matchingTrack)
      .max {
        ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
      }
  }

  private static func providerVideoAscending(
    _ lhs: LivePlaybackVideoSource,
    _ rhs: LivePlaybackVideoSource
  ) -> Bool {
    if lhs.height != rhs.height {
      return lhs.height < rhs.height
    }
    return (lhs.bitrate ?? 0) < (rhs.bitrate ?? 0)
  }

  private func failProviderRecovery() {
    providerRecoveryInProgress = false
    let failure = State.failed(
      "The selected instance could not provide a stable media source."
    )
    if state != failure {
      state = failure
    }
    stopPlaybackSession()
  }
}
