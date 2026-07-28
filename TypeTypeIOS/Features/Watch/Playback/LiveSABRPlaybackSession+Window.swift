import Foundation

extension LiveSABRPlaybackSession {
  func loadWindow() async throws -> LiveSABRPlaybackSnapshot {
    if let windowLoadTask {
      return try await windowLoadTask.task.value
    }
    let operationID = UUID()
    let task = Task { [weak self] () throws
      -> LiveSABRPlaybackSnapshot in
      guard let self else { throw CancellationError() }
      return try await self.performWindowLoad()
    }
    windowLoadTask = (operationID, task)
    do {
      let snapshot = try await task.value
      finishWindowLoad(operationID)
      recoveryCount = 0
      return snapshot
    } catch {
      finishWindowLoad(operationID)
      throw error
    }
  }

  func performWindowLoad() async throws -> LiveSABRPlaybackSnapshot {
    guard let control else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    try await reportPosition(control)
    var previousBufferedEdgeMS: Int64?
    var stagnantAttempts = 0
    for _ in 0..<Self.maximumAttempts {
      try Task.checkCancellation()
      let pending = try await service.prefetchSABRPlayback(
        sessionID: control.sessionID,
        request: windowRequest(for: control)
      )
      try validate(pending, against: control)
      if hasTerminalFailure(pending) {
        return try await recover(from: pending)
      }
      if pending.ready {
        let window = try await service.loadSABRSegments(
          sessionID: control.sessionID,
          request: windowRequest(for: control)
        )
        try validate(window, against: control)
        if hasTerminalFailure(window) {
          return try await recover(from: window)
        }
        if window.ready {
          try merge(window)
          guard let currentSnapshot else {
            throw LivePlaybackFailure.invalidSABRContract
          }
          return currentSnapshot
        }
        stagnantAttempts = nextStagnantAttempts(
          response: window,
          previousEdgeMS: previousBufferedEdgeMS,
          previousAttempts: stagnantAttempts
        )
        previousBufferedEdgeMS = window.bufferedEdgeMS
        try await pause(for: window, stagnantAttempts: stagnantAttempts)
      } else {
        stagnantAttempts = nextStagnantAttempts(
          response: pending,
          previousEdgeMS: previousBufferedEdgeMS,
          previousAttempts: stagnantAttempts
        )
        previousBufferedEdgeMS = pending.bufferedEdgeMS
        try await pause(for: pending, stagnantAttempts: stagnantAttempts)
      }
    }
    throw LivePlaybackFailure.sabrSessionTimedOut
  }

  private func finishWindowLoad(_ operationID: UUID) {
    guard windowLoadTask?.id == operationID else { return }
    windowLoadTask = nil
  }

  private func windowRequest(
    for control: LiveSABRPlaybackControl
  ) -> LiveSABRWindowRequest {
    LiveSABRWindowRequest(
      generation: control.generation,
      playerTimeMS: max(playerTimeMS, 0),
      videoItag: control.videoItag,
      audioItag: control.audioItag,
      audioTrackID: control.audioTrackID,
      playbackRate: playbackRate,
      bufferGoalMS: rateAwareBufferGoalMS,
      backBufferMS: Self.backBufferMS,
      bufferedRanges: bufferedRanges,
      audioOnly: preparation.audioOnly
    )
  }

  private func validate(
    _ response: LiveSABRWindowResponse,
    against control: LiveSABRPlaybackControl
  ) throws {
    guard response.sessionID == control.sessionID,
      response.generation == control.generation,
      self.control?.sessionID == control.sessionID,
      self.control?.generation == control.generation
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
  }

  private func hasTerminalFailure(
    _ response: LiveSABRWindowResponse
  ) -> Bool {
    response.terminalError?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ).isEmpty == false
  }

  private func nextStagnantAttempts(
    response: LiveSABRWindowResponse,
    previousEdgeMS: Int64?,
    previousAttempts: Int
  ) -> Int {
    guard let edge = response.bufferedEdgeMS,
      edge == previousEdgeMS
    else {
      return 0
    }
    return previousAttempts + 1
  }

  private func pause(
    for response: LiveSABRWindowResponse,
    stagnantAttempts: Int
  ) async throws {
    let requested = min(
      max(response.retryAfterMS ?? 500, Self.minimumRetryMS),
      Self.maximumRetryMS
    )
    let multiplier = Int64(1 << min(3, stagnantAttempts / 4))
    let delay = min(requested * multiplier, Self.maximumRetryMS)
    try await Task.sleep(for: .milliseconds(delay))
  }

  var bufferedRanges: [LiveSABRBufferedRange] {
    [audio, video].compactMap { track in
      guard let track, !track.segments.isEmpty else { return nil }
      return LiveSABRBufferedRange(
        itag: track.itag,
        startMS: track.startMS,
        endMS: track.endMS
      )
    }
  }

  private var rateAwareBufferGoalMS: Int64 {
    if live?.active == true || preparation.stream.isLive {
      return LiveSABRBufferPolicy.nativeLiveGoalMS(
        playbackRate: playbackRate
      )
    }
    return LiveSABRBufferPolicy.goalMS(
      isLive: false,
      playbackRate: playbackRate
    )
  }

  var currentSnapshot: LiveSABRPlaybackSnapshot? {
    guard let control, let audio else { return nil }
    return LiveSABRPlaybackSnapshot(
      sessionID: control.sessionID,
      generation: control.generation,
      startTimeMS: startTimeMS,
      durationMS: durationMS,
      endOfStream: endOfStream,
      audio: audio,
      video: video,
      live: live,
      index: index
    )
  }
}
