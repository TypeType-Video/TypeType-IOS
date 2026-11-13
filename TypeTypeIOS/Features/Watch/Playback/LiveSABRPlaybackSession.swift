import Foundation

actor LiveSABRPlaybackSession {
  let service: LivePlaybackServiceProtocol
  let preparation: LivePlaybackPreparation
  var control: LiveSABRPlaybackControl?
  var audio: LiveSABRTrackSnapshot?
  var video: LiveSABRTrackSnapshot?
  var startTimeMS: Int64 = 0
  var durationMS: Int64 = 0
  var endOfStream = false
  var live: LiveSABRLiveState?
  var index: LiveSABRPlaybackIndex?
  var playerTimeMS: Int64
  var playbackRate: Float = 1
  var lastReportedPlayerTimeMS: Int64 = -5_000
  var recoveryCount = 0
  var isReleased = false
  var attemptedVideoItags: Set<Int> = []
  var maintenanceTask: Task<Void, Never>?
  var maintenanceFailureCount = 0
  var windowLoadTask:
    (
      id: UUID,
      task: Task<LiveSABRPlaybackSnapshot, Error>
    )?
  let maintenanceFailureHandler: @Sendable (Error) -> Void

  init(
    service: LivePlaybackServiceProtocol,
    preparation: LivePlaybackPreparation,
    maintenanceFailureHandler: @escaping @Sendable (Error) -> Void = {
      _ in
    }
  ) {
    self.service = service
    self.preparation = preparation
    self.maintenanceFailureHandler = maintenanceFailureHandler
    playerTimeMS = Int64(preparation.resumeTime * 1_000)
  }

  func start() async throws -> LiveSABRPlaybackSnapshot {
    if let snapshot = currentSnapshot {
      return snapshot
    }
    guard let selectedVideo = preparation.video,
      let selectedAudio = preparation.audio
    else {
      throw LivePlaybackFailure.noPlayableSource
    }
    control = try await LivePlaybackDebugTrace.measure("sabr create") {
      try await createControl(
        videoItag: selectedVideo.itag,
        audioItag: selectedAudio.itag,
        audioTrackID: selectedAudio.audioTrackID
      )
    }
    attemptedVideoItags = [selectedVideo.itag]
    _ = try await LivePlaybackDebugTrace.measure("sabr window") { try await loadWindow() }
    let snapshot = try await LivePlaybackDebugTrace.measure("sabr index") { try await loadIndexedSnapshot() }
    startMaintenanceIfNeeded()
    return snapshot
  }

  func seek(
    to seconds: TimeInterval
  ) async throws -> LiveSABRPlaybackSnapshot {
    guard seconds.isFinite, let current = control else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    stopMaintenance()
    cancelWindowLoad()
    playerTimeMS = Int64(max(seconds, 0) * 1_000)
    let request = playbackRequest(
      videoItag: current.videoItag,
      audioItag: current.audioItag,
      audioTrackID: current.audioTrackID
    )
    do {
      let sought = try await service.seekSABRPlayback(
        sessionID: current.sessionID,
        request: request
      )
      try validateControl(
        sought,
        videoItag: current.videoItag,
        audioItag: current.audioItag,
        audioTrackID: current.audioTrackID,
        expectedSessionID: current.sessionID,
        previousGeneration: current.generation
      )
      control = sought
    } catch {
      guard isRecoverableControlFailure(error) else { throw error }
      adopt(try await createControl(
        videoItag: current.videoItag,
        audioItag: current.audioItag,
        audioTrackID: current.audioTrackID
      ))
    }
    resetWindow()
    recoveryCount = 0
    attemptedVideoItags = [current.videoItag]
    _ = try await loadWindow()
    let snapshot: LiveSABRPlaybackSnapshot
    do {
      snapshot = try await loadIndexedSnapshot()
    } catch {
      // After a seek the server can publish the new window slower than one index budget.
      try await Task.sleep(for: .milliseconds(Self.minimumRetryMS))
      snapshot = try await loadIndexedSnapshot()
    }
    startMaintenanceIfNeeded()
    return snapshot
  }

  func createControl(
    videoItag: Int,
    audioItag: Int,
    audioTrackID: String?
  ) async throws -> LiveSABRPlaybackControl {
    let request = playbackRequest(
      videoItag: videoItag,
      audioItag: audioItag,
      audioTrackID: audioTrackID
    )
    guard !isReleased else { throw CancellationError() }
    let created = try await service.createSABRPlayback(
      videoID: preparation.stream.id,
      request: request
    )
    try await discardIfReleased(created)
    try validateControl(
      created,
      videoItag: videoItag,
      audioItag: audioItag,
      audioTrackID: audioTrackID
    )
    return created
  }

  private func playbackRequest(
    videoItag: Int,
    audioItag: Int,
    audioTrackID: String?
  ) -> LiveSABRPlaybackRequest {
    LiveSABRPlaybackRequest(
      videoItag: videoItag,
      audioItag: audioItag,
      audioTrackID: audioTrackID,
      startTimeMS: playerTimeMS,
      playerTimeMS: playerTimeMS,
      audioOnly: preparation.audioOnly,
      isLive: preparation.stream.isLive
    )
  }

  private func validateControl(
    _ value: LiveSABRPlaybackControl,
    videoItag: Int,
    audioItag: Int,
    audioTrackID: String?,
    expectedSessionID: String? = nil,
    previousGeneration: Int64? = nil
  ) throws {
    let validPending = !value.ready
      && (Self.minimumRetryMS...Self.maximumRetryMS)
        .contains(value.retryAfterMS ?? -1)
    let validReady = value.ready && value.retryAfterMS == nil
    guard !value.sessionID.trimmingCharacters(
      in: .whitespacesAndNewlines
    ).isEmpty,
      value.videoID == preparation.stream.id,
      value.videoItag == videoItag,
      value.audioItag == audioItag,
      value.audioTrackID == audioTrackID,
      value.startTimeMS >= 0,
      value.generation >= 0,
      expectedSessionID.map({ value.sessionID == $0 }) ?? true,
      previousGeneration.map({ value.generation > $0 }) ?? true,
      validPending || validReady
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
  }

  private func isRecoverableControlFailure(_ error: Error) -> Bool {
    guard case let NetworkError.statusCode(code, _, _) = error else {
      return false
    }
    return [404, 409, 410].contains(code)
  }

  func resetWindow() {
    audio = nil
    video = nil
    startTimeMS = 0
    durationMS = 0
    endOfStream = false
    live = nil
    index = nil
  }

  func cancelWindowLoad() {
    windowLoadTask?.task.cancel()
    windowLoadTask = nil
  }

  private func loadIndexedSnapshot() async throws
    -> LiveSABRPlaybackSnapshot {
    guard let control else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let requiredAudioSegment = audio?.segments.map(\.sequence).max() ?? 0
    let requiredVideoSegment = preparation.audioOnly
      ? 0
      : video?.segments.map(\.sequence).max() ?? 0
    for attempt in 0..<Self.maximumAttempts {
      let value = try await service.loadSABRIndex(
        videoID: control.videoID,
        sessionID: control.sessionID
      )
      guard value.videoID == control.videoID,
        value.sessionID == control.sessionID,
        value.tracks.audio.itag == control.audioItag,
        value.tracks.video.itag == control.videoItag
      else {
        throw LivePlaybackFailure.invalidSABRContract
      }
      let knowsSegmentCount = value.tracks.audio.endSegment > 0
        && (preparation.audioOnly || value.tracks.video.endSegment > 0)
      let published = value.live
        || knowsSegmentCount
        || value.tracks.audio.maxSegment >= requiredAudioSegment
          && (
            preparation.audioOnly
              || value.tracks.video.maxSegment >= requiredVideoSegment
          )
      if published {
        index = value
        guard let currentSnapshot else {
          throw LivePlaybackFailure.invalidSABRContract
        }
        return currentSnapshot
      }
      guard attempt + 1 < Self.maximumAttempts else { break }
      try await Task.sleep(for: .milliseconds(
        Self.minimumRetryMS
      ))
    }
    throw LivePlaybackFailure.sabrSessionTimedOut
  }

  static let backBufferMS: Int64 = 30_000
  static let maximumAttempts = 60
  static let maximumRecoveries = 2
  static let maximumMaintenanceFailures = 5
  static let minimumRetryMS: Int64 = 250
  static let maximumRetryMS: Int64 = 2_000

  static func shouldStopMaintenance(failureCount: Int) -> Bool {
    failureCount >= maximumMaintenanceFailures
  }

  static func maintenanceRetryDelayMS(
    failureCount: Int
  ) -> Int64 {
    let exponent = min(max(failureCount, 0), 5)
    return min(1_000 * Int64(1 << exponent), 30_000)
  }
}
