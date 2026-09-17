import Foundation

extension LiveSABRPlaybackSession {
  func snapshot() async throws -> LiveSABRPlaybackSnapshot {
    if currentSnapshot == nil {
      if windowLoadTask != nil {
        return try await loadWindow()
      }
      return try await start()
    }
    startMaintenanceIfNeeded()
    guard let currentSnapshot else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    return currentSnapshot
  }

  func startMaintenanceIfNeeded() {
    guard maintenanceTask == nil,
      !endOfStream,
      live?.active == true || preparation.stream.isLive
    else {
      return
    }
    maintenanceTask = Task { [weak self] in
      while !Task.isCancelled {
        guard let self else { return }
        let delayMS = await self.maintenanceDelayMS()
        do {
          try await Task.sleep(for: .milliseconds(delayMS))
        } catch {
          return
        }
        await self.refreshWindowIfNeeded()
      }
    }
  }

  func stopMaintenance() {
    maintenanceTask?.cancel()
    maintenanceTask = nil
    maintenanceFailureCount = 0
  }

  private func refreshWindowIfNeeded() async {
    guard !Task.isCancelled, !endOfStream else { return }
    let edge = min(
      audio?.endMS ?? 0,
      preparation.audioOnly ? Int64.max : video?.endMS ?? 0
    )
    let playbackGoalMS = LiveSABRBufferPolicy.nativeLiveGoalMS(
      playbackRate: playbackRate
    )
    let thresholdMS = LiveSABRBufferPolicy.nativeLiveRefreshThresholdMS(
      for: playbackGoalMS
    )
    guard edge - playerTimeMS < thresholdMS else {
      maintenanceFailureCount = 0
      return
    }
    AppLogger.app.info(
      "Live SABR refresh started: player=\(self.playerTimeMS, privacy: .public) edge=\(edge, privacy: .public) threshold=\(thresholdMS, privacy: .public)"
    )
    do {
      _ = try await loadWindow()
      maintenanceFailureCount = 0
      let refreshedEdge = min(
        audio?.endMS ?? 0,
        preparation.audioOnly ? Int64.max : video?.endMS ?? 0
      )
      AppLogger.app.info(
        "Live SABR refresh completed: player=\(self.playerTimeMS, privacy: .public) edge=\(refreshedEdge, privacy: .public)"
      )
    } catch is CancellationError {
      return
    } catch {
      maintenanceFailureCount = min(
        maintenanceFailureCount + 1,
        20
      )
      let failure = error as NSError
      AppLogger.app.error(
        "Live SABR refresh failed: \(failure.domain, privacy: .public) \(failure.code) \(failure.localizedDescription, privacy: .public)"
      )
      guard Self.shouldStopMaintenance(
        failureCount: maintenanceFailureCount
      ) else {
        return
      }
      stopMaintenance()
      maintenanceFailureHandler(
        LivePlaybackFailure.sabrSessionTimedOut
      )
    }
  }

  private func maintenanceDelayMS() -> Int64 {
    Self.maintenanceRetryDelayMS(
      failureCount: maintenanceFailureCount
    )
  }
}
