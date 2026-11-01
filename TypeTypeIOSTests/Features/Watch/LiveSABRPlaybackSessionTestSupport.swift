import Foundation
@testable import TypeTypeIOS

final class RecoveryPlaybackService:
  LivePlaybackServiceProtocol, @unchecked Sendable {
  private(set) var createdVideoItags: [Int] = []
  private(set) var seekTimes: [Int64] = []
  private(set) var positionRates: [Float] = []
  private(set) var lifecycle: [String] = []
  private let recoveryAction: String
  private let retryVideoItags: [Int]
  private let recoveredPrefetchDelayMS: Int64

  init(
    recoveryAction: String = "retry_fresh_session",
    retryVideoItags: [Int] = [],
    recoveredPrefetchDelayMS: Int64 = 0
  ) {
    self.recoveryAction = recoveryAction
    self.retryVideoItags = retryVideoItags
    self.recoveredPrefetchDelayMS = recoveredPrefetchDelayMS
  }

  func stream(for videoURL: String) async throws -> LivePlaybackStream {
    throw LivePlaybackFailure.unavailableService
  }

  func prepare(
    stream: LivePlaybackStream,
    sourceURL: String,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    throw LivePlaybackFailure.unavailableService
  }

  func resourceData(for assetURL: URL) async throws -> Data {
    throw LivePlaybackFailure.unavailableService
  }

  var subtitlePayload: Data?

  func subtitleData(for source: LivePlaybackSubtitle) async throws -> Data {
    guard let subtitlePayload else { throw LivePlaybackFailure.unavailableService }
    return subtitlePayload
  }

  func createSABRPlayback(
    videoID: String,
    request: LiveSABRPlaybackRequest
  ) async throws -> LiveSABRPlaybackControl {
    lifecycle.append("create")
    createdVideoItags.append(request.videoItag)
    return LiveSABRPlaybackControl(
      sessionID: createdVideoItags.count == 1
        ? "initial"
        : "recovered",
      videoID: videoID,
      videoItag: request.videoItag,
      audioItag: request.audioItag,
      audioTrackID: request.audioTrackID,
      startTimeMS: request.startTimeMS,
      generation: 0,
      ready: false,
      status: "idle",
      retryAfterMS: 250,
      live: nil
    )
  }

  func prefetchSABRPlayback(
    sessionID: String,
    request: LiveSABRWindowRequest
  ) async throws -> LiveSABRWindowResponse {
    lifecycle.append("prefetch")
    if sessionID == "initial" {
      return LiveSABRWindowResponse(
        sessionID: sessionID,
        generation: request.generation,
        ready: false,
        retryAfterMS: 250,
        status: "terminal",
        durationMS: nil,
        endOfStream: nil,
        audio: nil,
        video: nil,
        startTimeMS: nil,
        playerTimeMS: request.playerTimeMS,
        readerHeadMS: nil,
        readerTailMS: nil,
        bufferedEdgeMS: request.playerTimeMS,
        terminalError: "no media",
        recoveryAction: recoveryAction,
        retryVideoItags: retryVideoItags,
        live: nil
      )
    }
    if recoveredPrefetchDelayMS > 0 {
      try await Task.sleep(
        for: .milliseconds(recoveredPrefetchDelayMS)
      )
    }
    return LiveSABRWindowResponse(
      sessionID: sessionID,
      generation: request.generation,
      ready: true,
      retryAfterMS: nil,
      status: nil,
      durationMS: 600_000,
      endOfStream: false,
      audio: nil,
      video: nil,
      startTimeMS: request.playerTimeMS,
      playerTimeMS: request.playerTimeMS,
      readerHeadMS: request.playerTimeMS,
      readerTailMS: request.playerTimeMS,
      bufferedEdgeMS: request.playerTimeMS + 60_000,
      terminalError: nil,
      recoveryAction: nil,
      retryVideoItags: nil,
      live: nil
    )
  }

  func loadSABRSegments(
    sessionID: String,
    request: LiveSABRWindowRequest
  ) async throws -> LiveSABRWindowResponse {
    lifecycle.append("segments")
    return LiveSABRWindowResponse(
      sessionID: sessionID,
      generation: request.generation,
      ready: true,
      retryAfterMS: nil,
      status: "ready",
      durationMS: 600_000,
      endOfStream: false,
      audio: track(
        sessionID: sessionID,
        generation: request.generation,
        itag: 140,
        mime: "audio/mp4",
        startMS: request.playerTimeMS
      ),
      video: track(
        sessionID: sessionID,
        generation: request.generation,
        itag: createdVideoItags.last ?? 136,
        mime: "video/mp4",
        startMS: request.playerTimeMS
      ),
      startTimeMS: request.playerTimeMS,
      playerTimeMS: request.playerTimeMS,
      readerHeadMS: request.playerTimeMS,
      readerTailMS: request.playerTimeMS,
      bufferedEdgeMS: request.playerTimeMS + 60_000,
      terminalError: nil,
      recoveryAction: nil,
      retryVideoItags: nil,
      live: nil
    )
  }

  func loadSABRIndex(
    videoID: String,
    sessionID: String
  ) async throws -> LiveSABRPlaybackIndex {
    lifecycle.append("index")
    return LiveSABRPlaybackIndex(
      videoID: videoID,
      sessionID: sessionID,
      live: false,
      tracks: .init(
        audio: .init(
          itag: 140,
          maxSegment: 120,
          endSegment: 120,
          bufferedEndMS: 60_000
        ),
        video: .init(
          itag: createdVideoItags.last ?? 133,
          maxSegment: 120,
          endSegment: 120,
          bufferedEndMS: 60_000
        )
      )
    )
  }

  func updateSABRPosition(
    sessionID: String,
    request: LiveSABRPositionRequest
  ) async throws -> LiveSABRPositionResponse {
    lifecycle.append("position")
    positionRates.append(request.playbackRate)
    return LiveSABRPositionResponse(
      sessionID: sessionID,
      generation: request.generation,
      playerTimeMS: request.playerTimeMS,
      readerHeadMS: request.playerTimeMS,
      readerTailMS: request.playerTimeMS,
      bufferedEdgeMS: request.playerTimeMS,
      live: nil
    )
  }

  func seekSABRPlayback(
    sessionID: String,
    request: LiveSABRPlaybackRequest
  ) async throws -> LiveSABRPlaybackControl {
    seekTimes.append(request.startTimeMS)
    return LiveSABRPlaybackControl(
      sessionID: sessionID,
      videoID: "video",
      videoItag: request.videoItag,
      audioItag: request.audioItag,
      audioTrackID: request.audioTrackID,
      startTimeMS: request.startTimeMS,
      generation: 1,
      ready: false,
      status: "repositioning",
      retryAfterMS: 250,
      live: nil
    )
  }

  func authenticatedSABRResourceURL(
    for value: String
  ) throws -> URL {
    guard let url = URL(
      string: "typetype-sabr://instance.example\(value)"
    ) else {
      throw LivePlaybackFailure.invalidServerResource
    }
    return url
  }

  private func track(
    sessionID: String,
    generation: Int64,
    itag: Int,
    mime: String,
    startMS: Int64
  ) -> LiveSABRWindowTrack {
    LiveSABRWindowTrack(
      mime: mime,
      initURL: "/sabr/playback/\(sessionID)/\(itag)"
        + "/init?generation=\(generation)",
      segments: [
        LiveSABRWindowSegment(
          url: "/sabr/playback/\(sessionID)/\(itag)"
            + "/segment/1?generation=\(generation)",
          startMS: startMS,
          durationMS: 5_000
        )
      ]
    )
  }
}
