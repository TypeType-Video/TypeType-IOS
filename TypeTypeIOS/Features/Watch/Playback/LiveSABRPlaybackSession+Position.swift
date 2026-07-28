import Foundation

extension LiveSABRPlaybackSession {
  func updatePlayerTime(_ seconds: TimeInterval) async {
    guard seconds.isFinite else { return }
    playerTimeMS = Int64(max(seconds, 0) * 1_000)
    guard playerTimeMS - lastReportedPlayerTimeMS >= 5_000 else {
      return
    }
    await reportPosition()
  }

  func updatePlaybackRate(_ rate: Float) async {
    let supportedRate = min(max(rate, 0.25), 4)
    guard playbackRate != supportedRate else { return }
    playbackRate = supportedRate
    await reportPosition()
  }

  private func reportPosition() async {
    guard let control else { return }
    let reportedTime = playerTimeMS
    try? await reportPosition(control, playerTimeMS: reportedTime)
  }

  func reportPosition(
    _ control: LiveSABRPlaybackControl,
    playerTimeMS: Int64? = nil
  ) async throws {
    let request = LiveSABRPositionRequest(
      generation: control.generation,
      playerTimeMS: max(playerTimeMS ?? self.playerTimeMS, 0),
      videoItag: control.videoItag,
      audioItag: control.audioItag,
      audioTrackID: control.audioTrackID,
      playbackRate: playbackRate,
      bufferedRanges: bufferedRanges,
      audioOnly: preparation.audioOnly
    )
    let response = try await service.updateSABRPosition(
      sessionID: control.sessionID,
      request: request
    )
    guard response.sessionID == control.sessionID,
      response.generation == control.generation,
      self.control?.sessionID == control.sessionID,
      self.control?.generation == control.generation
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    if let updatedLive = response.live {
      live = updatedLive
    }
    lastReportedPlayerTimeMS = request.playerTimeMS
  }
}
