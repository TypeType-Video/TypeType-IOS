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
    let activeLive = response.live?.active == true
      || live?.active == true
      || preparation.stream.isLive
    let seekableStartMS = response.live?.seekableStartMS
      ?? live?.seekableStartMS
    audio = try mergeTrack(
      current: audio,
      incoming: incomingAudio,
      itag: control?.audioItag,
      expectedKind: "audio",
      activeLive: activeLive,
      seekableStartMS: seekableStartMS
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
        expectedKind: "video",
        activeLive: activeLive,
        seekableStartMS: seekableStartMS
      )
      incomingEndMS = min(
        incomingEndMS,
        try endMS(of: incomingVideo)
      )
    }
    let withinPresentation = Self.windowFitsPresentation(
      incomingEndMS: incomingEndMS,
      durationMS: responseDurationMS,
      live: response.live
    )
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

  static func windowFitsPresentation(
    incomingEndMS: Int64,
    durationMS: Int64,
    live: LiveSABRLiveState?
  ) -> Bool {
    if let live, live.active {
      let presentationHeadMS = max(durationMS, live.headTimeMS)
      guard live.headSequence >= 0,
        live.headTimeMS >= 0,
        live.seekableStartMS >= 0,
        live.seekableEndMS >= live.seekableStartMS,
        live.headTimeMS >= live.seekableEndMS,
        live.targetLatencyMS >= 0,
        presentationHeadMS <= Int64.max - maximumLiveLeadMS
      else {
        return false
      }
      return incomingEndMS <= presentationHeadMS + maximumLiveLeadMS
    }
    return incomingEndMS <= durationMS
      || incomingEndMS - durationMS <= 2_000
  }

  private static let maximumLiveLeadMS: Int64 = 60_000

  /// Server segment times are rounded per segment, so consecutive segments
  /// can overlap by a few milliseconds (seen: 3-4 ms on resumed videos). A
  /// small overlap is the same timeline; a real gap backwards is not.
  static let segmentOverlapToleranceMS: Int64 = 50

  static func segmentFollows(startMS: Int64, previousEndMS: Int64) -> Bool {
    previousEndMS < 0 || startMS + segmentOverlapToleranceMS >= previousEndMS
  }

  private func mergeTrack(
    current: LiveSABRTrackSnapshot?,
    incoming: LiveSABRWindowTrack,
    itag: Int?,
    expectedKind: String,
    activeLive: Bool,
    seekableStartMS: Int64?
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
    if activeLive {
      segments = Self.retainedLiveSegments(
        segments,
        playerTimeMS: playerTimeMS,
        seekableStartMS: seekableStartMS
      )
    }
    var known = Set(segments.map(\.url))
    var previousEndMS: Int64 = -1
    for item in incoming.segments {
      guard item.startMS >= 0,
        item.durationMS > 0,
        Self.segmentFollows(startMS: item.startMS, previousEndMS: previousEndMS),
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
    if activeLive {
      segments = Self.retainedLiveSegments(
        segments,
        playerTimeMS: playerTimeMS,
        seekableStartMS: seekableStartMS
      )
    }
    return LiveSABRTrackSnapshot(
      itag: itag,
      mime: incoming.mime,
      initURL: initURL,
      segments: segments
    )
  }

  static func retainedLiveSegments(
    _ segments: [LiveSABRMediaSegment],
    playerTimeMS: Int64,
    seekableStartMS: Int64?
  ) -> [LiveSABRMediaSegment] {
    guard !segments.isEmpty else { return [] }
    let playbackFloor = max(
      playerTimeMS - backBufferMS - liveRetentionMarginMS,
      0
    )
    let floor = max(playbackFloor, seekableStartMS ?? 0)
    let retained = segments.filter {
      $0.startMS + $0.durationMS > floor
    }
    let usable = retained.isEmpty
      ? Array(segments.suffix(1))
      : retained
    return Array(usable.suffix(maximumRetainedLiveSegments))
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

  private static let liveRetentionMarginMS: Int64 = 10_000
  private static let maximumRetainedLiveSegments = 1_024
}
