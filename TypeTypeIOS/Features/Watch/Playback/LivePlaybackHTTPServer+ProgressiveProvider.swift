import Foundation

extension LivePlaybackHTTPServer {
  func startProgressiveProviderSession() async throws -> String {
    guard let providerPlayback = preparation.providerPlayback,
      case let .separateProgressive(videoURL, audioURL) =
        providerPlayback,
      let video = preparation.video,
      let audio = preparation.audio
    else {
      throw LivePlaybackFailure.invalidPlaylist
    }

    async let videoPlaylist = progressiveProviderPlaylist(
      sourceURL: videoURL,
      initStart: video.initStart,
      initEnd: video.initEnd,
      indexStart: video.indexStart,
      indexEnd: video.indexEnd,
      mimeType: "video/mp4",
      preflightDuration: Self.providerPreflightDuration
    )
    async let audioPlaylist = progressiveProviderPlaylist(
      sourceURL: audioURL,
      initStart: audio.initStart,
      initEnd: audio.initEnd,
      indexStart: audio.indexStart,
      indexEnd: audio.indexEnd,
      mimeType: "audio/mp4",
      preflightDuration: 10
    )
    let playlists = try await (videoPlaylist, audioPlaylist)
    providerProgressiveVideo = playlists.0
    providerProgressiveAudio = playlists.1

    let videoRoute = register(
      target: .providerProgressiveVideo,
      pathExtension: "m3u8"
    )
    let audioRoute = register(
      target: .providerProgressiveAudio,
      pathExtension: "m3u8"
    )
    guard
      let localVideoURL = localURL(
        routeID: videoRoute,
        extension: "m3u8"
      ),
      let localAudioURL = localURL(
        routeID: audioRoute,
        extension: "m3u8"
      )
    else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }

    providerProgressiveMaster = progressiveProviderMasterPlaylist(
      videoURL: localVideoURL,
      audioURL: localAudioURL
    )
    return register(
      target: .providerMaster,
      pathExtension: "m3u8"
    )
  }

  private func progressiveProviderPlaylist(
    sourceURL: URL,
    initStart: Int64,
    initEnd: Int64,
    indexStart: Int64,
    indexEnd: Int64,
    mimeType: String,
    preflightDuration: TimeInterval
  ) async throws -> String {
    guard initStart >= 0, initEnd >= initStart,
      indexStart > initEnd, indexEnd >= indexStart,
      initEnd <= Int64(Int.max), indexEnd <= Int64(Int.max)
    else {
      throw LivePlaybackFailure.invalidPlaylist
    }
    let indexRange = Int(indexStart)...Int(indexEnd)
    let indexData = try await service.resourceData(
      for: sourceURL,
      range: indexRange
    )
    let index = try LiveProviderSegmentIndex.parse(indexData)

    let initRoute = register(
      target: .upstreamRange(
        sourceURL,
        Int(initStart)...Int(initEnd),
        mimeType
      ),
      pathExtension: "mp4"
    )
    guard let initURL = localURL(
      routeID: initRoute,
      extension: "mp4"
    ) else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }

    var lines = [
      "#EXTM3U",
      "#EXT-X-VERSION:7",
      "#EXT-X-TARGETDURATION:\(providerTargetDuration(index))",
      "#EXT-X-MEDIA-SEQUENCE:0",
      "#EXT-X-PLAYLIST-TYPE:VOD",
      "#EXT-X-INDEPENDENT-SEGMENTS",
      "#EXT-X-MAP:URI=\"\(initURL.absoluteString)\"",
    ]
    var offset = indexEnd + 1 + index.firstOffset
    var registeredDuration: TimeInterval = 0
    var warmRoutes: [Route] = []
    for reference in index.references {
      guard offset >= 0,
        offset <= Int64(Int.max),
        Int64(reference.byteCount) <= Int64(Int.max) - offset
      else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      let upperBound = offset + Int64(reference.byteCount) - 1
      let range = Int(offset)...Int(upperBound)
      let target = Target.upstreamRange(
        sourceURL,
        range,
        mimeType
      )
      let route = register(
        target: target,
        pathExtension: "m4s"
      )
      if registeredDuration < preflightDuration {
        warmRoutes.append(Route(target: target, pathExtension: "m4s"))
      }
      guard let segmentURL = localURL(
        routeID: route,
        extension: "m4s"
      ) else {
        throw LivePlaybackFailure.localPlaybackUnavailable
      }
      lines.append(
        String(format: "#EXTINF:%.6f,", reference.duration)
      )
      lines.append(segmentURL.absoluteString)
      offset = upperBound + 1
      registeredDuration += reference.duration
    }
    lines.append("#EXT-X-ENDLIST")
    lines.append("")
    try await warmProgressiveStart(warmRoutes)
    return lines.joined(separator: "\n")
  }

  /// The first segment loads before playback so a broken source fails fast and the fallback runs;
  /// the rest warms in the background through `load(_:)`.
  private func warmProgressiveStart(_ routes: [Route]) async throws {
    guard let first = routes.first else { return }
    _ = try await load(first)
    let rest = Array(routes.dropFirst())
    guard !rest.isEmpty else { return }
    Task.detached(priority: .userInitiated) { [weak self] in
      for route in rest {
        guard let self, !Task.isCancelled else { return }
        _ = try? await self.load(route)
      }
    }
  }

  private static let providerPreflightDuration: TimeInterval = 20

  private func providerTargetDuration(
    _ index: LiveProviderSegmentIndex
  ) -> Int {
    max(
      Int(ceil(index.references.map(\.duration).max() ?? 1)),
      1
    )
  }

  private func progressiveProviderMasterPlaylist(
    videoURL: URL,
    audioURL: URL
  ) -> String {
    let videoBitrate = preparation.video?.bitrate ?? 1_500_000
    let audioBitrate = preparation.audio?.bitrate ?? 128_000
    var attributes = [
      "BANDWIDTH=\(max(videoBitrate + audioBitrate, 256_000))",
      "AUDIO=\"provider-audio\"",
    ]
    if let video = preparation.video,
      video.width > 0, video.height > 0 {
      attributes.append("RESOLUTION=\(video.width)x\(video.height)")
    }
    let audioName = hlsQuoted(
      preparation.audio?.displayName ?? "Default"
    )
    return [
      "#EXTM3U",
      "#EXT-X-VERSION:7",
      "#EXT-X-INDEPENDENT-SEGMENTS",
      "#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"provider-audio\","
        + "NAME=\"\(audioName)\",DEFAULT=YES,AUTOSELECT=YES,"
        + "URI=\"\(audioURL.absoluteString)\"",
      "#EXT-X-STREAM-INF:\(attributes.joined(separator: ","))",
      videoURL.absoluteString,
      "",
    ].joined(separator: "\n")
  }
}
