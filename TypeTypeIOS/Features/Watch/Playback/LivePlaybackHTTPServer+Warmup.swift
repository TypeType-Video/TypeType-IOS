import Foundation

extension LivePlaybackHTTPServer {
  /// Number of media segments per track loaded before the player asks.
  static let warmupSegmentCount = 2

  /// Starts loading what the player requests first (each track's playlist,
  /// init segment and first media segments) as soon as the SABR session is
  /// ready, instead of one round trip at a time once AVPlayer asks. The
  /// loads go through `load(_:)`, so the player's own requests join them
  /// or hit the cache.
  func warmSABRStart() {
    warmTracks([sabrAudioRouteID, sabrVideoRouteID].compactMap { $0 })
  }

  /// Same warm-up for provider HLS (NicoNico): both media playlists, their
  /// key and init segment, and the first segments.
  func warmProviderHLSStart() {
    guard case let .separateHLS(videoURL, audioURL)? = preparation.providerPlayback else { return }
    warmTracks([
      register(target: .upstream(videoURL), pathExtension: "m3u8"),
      register(target: .upstream(audioURL), pathExtension: "m3u8"),
    ])
  }

  private func warmTracks(_ trackRouteIDs: [String]) {
    Task.detached(priority: .userInitiated) { [weak self] in
      await withTaskGroup(of: Void.self) { group in
        for routeID in trackRouteIDs {
          group.addTask { [weak self] in await self?.warmTrack(routeID: routeID) }
        }
      }
    }
  }

  private func warmTrack(routeID: String) async {
    guard let playlistRoute = route(for: "/resource/\(routeID).m3u8"),
      let playlist = try? await load(playlistRoute)
    else { return }
    let paths = Self.startResourcePaths(
      in: String(decoding: playlist.data, as: UTF8.self),
      segmentCount: Self.warmupSegmentCount
    )
    await withTaskGroup(of: Void.self) { group in
      for path in paths {
        guard let route = route(for: path) else { continue }
        group.addTask { [weak self] in _ = try? await self?.load(route) }
      }
    }
  }

  /// Local paths of a media playlist's init segment, key and the first
  /// segments the player will play: from `#EXT-X-START` when the playlist
  /// resumes mid-video, so a resume never warms (and asks the server for)
  /// the beginning of the video.
  static func startResourcePaths(in playlist: String, segmentCount: Int) -> [String] {
    var paths: [String] = []
    var startOffset: Double = 0
    var elapsed: Double = 0
    var pendingDuration: Double = 0
    var segments = 0
    for rawLine in playlist.split(whereSeparator: \.isNewline) {
      let line = rawLine.trimmingCharacters(in: .whitespaces)
      if line.hasPrefix("#EXT-X-START:"), let value = attribute("TIME-OFFSET", in: line) {
        startOffset = max(Double(value) ?? 0, 0)
      } else if line.hasPrefix("#EXT-X-MAP:") || line.hasPrefix("#EXT-X-KEY:"),
        let value = attribute("URI", in: line), let url = URL(string: value) {
        paths.append(url.path)
      } else if line.hasPrefix("#EXTINF:") {
        let value = line.dropFirst("#EXTINF:".count).split(separator: ",").first ?? ""
        pendingDuration = Double(value) ?? 0
      } else if !line.isEmpty, !line.hasPrefix("#"), let url = URL(string: line) {
        elapsed += pendingDuration
        pendingDuration = 0
        // Segments that end before the start position are never played.
        guard elapsed > startOffset else { continue }
        paths.append(url.path)
        segments += 1
        if segments >= segmentCount { break }
      }
    }
    return paths
  }

  private static func attribute(_ name: String, in line: String) -> String? {
    guard let range = line.range(of: "\(name)=") else { return nil }
    var value = line[range.upperBound...]
    if value.hasPrefix("\"") {
      value = value.dropFirst()
      return value.firstIndex(of: "\"").map { String(value[..<$0]) }
    }
    return String(value.prefix { $0 != "," })
  }
}

extension LivePlaybackHTTPServer.Route {
  /// Short label for debug traces; never includes tokens.
  var debugName: String {
    switch target {
    case let .upstream(url): return "upstream \(url.path.suffix(24))"
    case let .upstreamRange(url, range, _): return "range \(url.path.suffix(16)) \(range.lowerBound)-\(range.upperBound)"
    case .sabrMaster: return "sabr master"
    case let .sabrTrack(kind): return "sabr track \(kind)"
    default: return "\(target)".prefix(40).description
    }
  }
}
