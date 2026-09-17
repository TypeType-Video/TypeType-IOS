import Foundation

extension LivePlaybackHTTPServer {
  func startSABRSession() async throws -> String {
    let session = LiveSABRPlaybackSession(
      service: service,
      preparation: preparation,
      maintenanceFailureHandler: { [weak self] error in
        guard let self else { return }
        self.sabrFailureHandler?(error)
      }
    )
    sabrSession = session
    let snapshot = try await session.start()
    sabrMasterBaseURL = snapshot.audio.initURL
    sabrPlaybackStartTime = snapshot.isIndexedVOD
      ? 0
      : TimeInterval(snapshot.startTimeMS) / 1_000
    sabrAudioRouteID = register(
      target: .sabrTrack(.audio),
      pathExtension: "m3u8"
    )
    if !preparation.audioOnly {
      sabrVideoRouteID = register(
        target: .sabrTrack(.video),
        pathExtension: "m3u8"
      )
    }
    let masterRouteID = register(
      target: .sabrMaster,
      pathExtension: "m3u8"
    )
    sabrMasterRouteID = masterRouteID
    return masterRouteID
  }

  func loadSABRMaster() async throws -> Resource {
    guard let audioRouteID = sabrAudioRouteID,
      let audioURL = localURL(
        routeID: audioRouteID,
        extension: "m3u8"
      )
    else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }
    let videoURL = sabrVideoRouteID.flatMap {
      localURL(routeID: $0, extension: "m3u8")
    }
    guard let sabrSession else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }
    let snapshot = try await sabrSession.snapshot()
    let data = LiveSABRPlaylistBuilder.master(
      preparation: preparation,
      snapshot: snapshot,
      audioURL: audioURL,
      videoURL: videoURL
    )
    guard let sabrMasterBaseURL else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    return Resource(
      data: try rewritePlaylist(
        data,
        upstreamURL: sabrMasterBaseURL
      ),
      mimeType: Self.playlistMIME
    )
  }

  func loadSABRTrack(
    _ kind: LiveSABRTrackKind
  ) async throws -> Resource {
    guard let sabrSession else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }
    let snapshot = try await sabrSession.snapshot()
    let track: LiveSABRTrackSnapshot?
    switch kind {
    case .audio:
      track = snapshot.audio
    case .video:
      track = snapshot.video
    }
    guard let track else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let data = try LiveSABRPlaylistBuilder.media(
      track: track,
      snapshot: snapshot,
      kind: kind
    )
    return Resource(
      data: try rewritePlaylist(data, upstreamURL: track.initURL),
      mimeType: Self.playlistMIME
    )
  }
}
