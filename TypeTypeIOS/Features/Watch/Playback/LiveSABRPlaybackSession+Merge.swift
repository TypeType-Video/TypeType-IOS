import Foundation

extension LiveSABRPlaybackSession {
  func merge(_ response: LiveSABRWindowResponse) throws {
    guard response.ready,
      let incomingAudio = response.audio,
      let responseDurationMS = response.durationMS,
      responseDurationMS > 0
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let responseStartMS = response.startTimeMS ?? playerTimeMS
    audio = try mergeTrack(
      current: audio,
      incoming: incomingAudio,
      itag: control?.audioItag,
      expectedKind: "audio"
    )
    var incomingEndMS = try endMS(of: incomingAudio)
    if !preparation.audioOnly {
      guard let incomingVideo = response.video else {
        throw LivePlaybackFailure.invalidSABRContract
      }
      video = try mergeTrack(
        current: video,
        incoming: incomingVideo,
        itag: control?.videoItag,
        expectedKind: "video"
      )
      incomingEndMS = min(
        incomingEndMS,
        try endMS(of: incomingVideo)
      )
    }
    let withinPresentation = incomingEndMS <= responseDurationMS
      || incomingEndMS - responseDurationMS <= 2_000
    guard responseStartMS >= 0,
      incomingEndMS > responseStartMS,
      withinPresentation
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    startTimeMS = responseStartMS
    durationMS = responseDurationMS
    endOfStream = response.endOfStream ?? endOfStream
    live = response.live ?? live
  }

  private func mergeTrack(
    current: LiveSABRTrackSnapshot?,
    incoming: LiveSABRWindowTrack,
    itag: Int?,
    expectedKind: String
  ) throws -> LiveSABRTrackSnapshot {
    let mediaKind = incoming.mime.split(separator: ";")
      .first?.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    guard let itag,
      mediaKind?.hasPrefix("\(expectedKind)/") == true,
      !incoming.segments.isEmpty
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let initURL = try validatedResourceURL(
      incoming.initURL,
      itag: itag,
      initialization: true
    )
    var segments = current?.segments ?? []
    var known = Set(segments.map(\.url))
    var previousEndMS: Int64 = -1
    for item in incoming.segments {
      guard item.startMS >= 0,
        item.durationMS > 0,
        previousEndMS < 0 || item.startMS + 1 >= previousEndMS,
        item.startMS <= Int64.max - item.durationMS
      else {
        throw LivePlaybackFailure.invalidSABRContract
      }
      let url = try validatedResourceURL(
        item.url,
        itag: itag,
        initialization: false
      )
      if known.insert(url).inserted {
        segments.append(
          LiveSABRMediaSegment(
            url: url,
            startMS: item.startMS,
            durationMS: item.durationMS
          )
        )
      }
      previousEndMS = item.startMS + item.durationMS
    }
    guard !segments.isEmpty else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    segments.sort { $0.startMS < $1.startMS }
    return LiveSABRTrackSnapshot(
      itag: itag,
      mime: incoming.mime,
      initURL: initURL,
      segments: segments
    )
  }

  private func endMS(
    of track: LiveSABRWindowTrack
  ) throws -> Int64 {
    guard let last = track.segments.last,
      last.durationMS > 0,
      last.startMS <= Int64.max - last.durationMS
    else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    return last.startMS + last.durationMS
  }

  private func validatedResourceURL(
    _ value: String,
    itag: Int,
    initialization: Bool
  ) throws -> URL {
    guard let control else {
      throw LivePlaybackFailure.invalidSABRContract
    }
    let url = try service.authenticatedSABRResourceURL(for: value)
    try LiveSABRResourceValidator.validate(
      url,
      sessionID: control.sessionID,
      generation: control.generation,
      itag: itag,
      initialization: initialization
    )
    return url
  }
}
