import Foundation

extension LivePlayerController {
  func retryAfterNetworkRecovery() {
    guard needsNetworkRecovery else { return }
    guard providerRecoveryDesiredAutoplay else {
      if case .failed = state {
        retry()
      }
      return
    }
    guard let service, let stream, let preparation else {
      retry()
      return
    }

    let restartTime = max(
      position,
      providerRecoveryResumeTime,
      preparation.resumeTime,
      0
    )
    if preparation.isSABR {
      sabrStallRecoveryTask?.cancel()
      sabrStallRecoveryTask = nil
      sabrRecoveryBudgetResetTask?.cancel()
      sabrRecoveryBudgetResetTask = nil
      sabrStallRecoveryCount = 0
      recoverSABRFromStall()
      return
    }

    state = .loading
    loadTask?.cancel()
    loadTask = Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let recovered = try service.prepare(
          stream: stream,
          sourceURL: video.url,
          preferences: preferences
        )
        try Task.checkCancellation()
        resetProviderRecoveryState(
          for: recovered,
          autoplay: true
        )
        try await installWithProviderFallback(
          recovered,
          autoplay: true,
          seekOverride: restartTime
        )
      } catch is CancellationError {
        return
      } catch {
        Self.logPreparationFailure(error)
        state = .failed(Self.message(for: error))
        stopPlaybackSession()
      }
    }
  }

  private var needsNetworkRecovery: Bool {
    switch state {
    case .loading, .failed:
      return true
    case .idle, .ready, .playing, .paused:
      return false
    }
  }
}
