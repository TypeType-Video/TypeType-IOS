import Foundation

extension LivePlayerController {
  static let startupBudget: Duration = .seconds(20)

  func armStartupWatchdog() {
    startupWatchdog?.cancel()
    startupWatchdog = Task { [weak self] in
      try? await Task.sleep(for: Self.startupBudget)
      guard !Task.isCancelled, let self, startupTrace.isRunning else { return }
      if retryStartupOnce(reason: "startup budget exceeded") { return }
      startupTrace = LivePlaybackStartupTrace()
      state = .failed(String(localized: "The video took too long to start. Check your connection and try again."))
      stopPlaybackSession()
    }
  }

  func retryStartupOnce(reason: String) -> Bool {
    guard !startupRetryUsed else { return false }
    startupRetryUsed = true
    AppLogger.playback.notice("startup retry: \(reason, privacy: .public)")
    loadTask?.cancel()
    let videoURL = video.url
    loadTask = Task { [weak self, service] in
      await service?.discardPendingStreams(for: videoURL)
      await self?.load()
    }
    return true
  }

  static func isTransientStartupFailure(_ error: Error) -> Bool {
    if let failure = error as? LivePlaybackFailure {
      switch failure {
      case .invalidSABRContract, .sabrSessionTimedOut, .localPlaybackUnavailable:
        return true
      default:
        return false
      }
    }
    if let network = error as? NetworkError {
      if case let .statusCode(code, _) = network { return code >= 500 || code == 408 || code == 429 }
      return true
    }
    return (error as NSError).domain == NSURLErrorDomain
  }
}
