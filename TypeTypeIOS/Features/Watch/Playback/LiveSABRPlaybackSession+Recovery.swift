import Foundation

extension LiveSABRPlaybackSession {
  func recover(
    from response: LiveSABRWindowResponse
  ) async throws -> LiveSABRPlaybackSnapshot {
    AppLogger.playback.notice(
      "sabr terminal error=\(response.terminalError ?? "", privacy: .public) action=\(response.recoveryAction ?? "none", privacy: .public) recoveries=\(self.recoveryCount) audioOnly=\(self.preparation.audioOnly)"
    )
    guard recoveryCount < Self.maximumRecoveries,
      let current = control
    else {
      throw LivePlaybackFailure.sabrSessionFailed
    }
    let nextVideoItag: Int
    switch response.recoveryAction {
    case "retry_fresh_session":
      nextVideoItag = current.videoItag
    case "retry_fresh_session_lower_video_itag":
      guard let candidate = lowerVideoItag(from: response) else {
        throw LivePlaybackFailure.sabrSessionFailed
      }
      nextVideoItag = candidate
    default:
      throw LivePlaybackFailure.sabrSessionFailed
    }
    recoveryCount += 1
    adopt(try await createControl(
      videoItag: nextVideoItag,
      audioItag: current.audioItag,
      audioTrackID: current.audioTrackID
    ))
    attemptedVideoItags.insert(nextVideoItag)
    resetWindow()
    return try await performWindowLoad()
  }

  private func lowerVideoItag(
    from response: LiveSABRWindowResponse
  ) -> Int? {
    let originalHeight = preparation.video?.height ?? Int.max
    let supported = preparation.stream.allVideoSources.filter {
      $0.isSABR && $0.isAppleH264 && $0.itag > 0
        && $0.height <= originalHeight
        && !attemptedVideoItags.contains($0.itag)
    }
    let supportedItags = Set(supported.map(\.itag))
    return response.retryVideoItags?.first {
      supportedItags.contains($0)
    }
  }
}
