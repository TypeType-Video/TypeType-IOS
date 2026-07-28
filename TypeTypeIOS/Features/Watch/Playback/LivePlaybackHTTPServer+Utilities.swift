import Foundation

extension LivePlaybackHTTPServer {
  func mimeType(for route: Route) -> String {
    switch route.target {
    case let .upstream(url):
      return upstreamMIMEType(for: url)
    case .sabrMaster, .sabrTrack, .providerMaster:
      return Self.playlistMIME
    case .subtitlePlaylist:
      return Self.playlistMIME
    case .subtitleVTT:
      return "text/vtt"
    }
  }

  func upstreamMIMEType(for url: URL) -> String {
    if localExtension(for: url) == "m3u8" {
      return Self.playlistMIME
    }
    if let audioItag = preparation.audio?.itag,
      url.path.contains("/\(audioItag)/") {
      return "audio/mp4"
    }
    return "video/mp4"
  }

  func localExtension(for url: URL) -> String {
    let query = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    )?.queryItems ?? []
    if url.pathExtension.lowercased() == "m3u8"
      || query.contains(where: {
        $0.name == "format" && $0.value == "hls"
      })
      || query.contains(where: { $0.name == "playlist" }) {
      return "m3u8"
    }
    return "m4s"
  }

  func isPlaylist(_ data: Data) -> Bool {
    guard data.count >= 7 else { return false }
    return String(
      data: data.prefix(7),
      encoding: .utf8
    ) == "#EXTM3U"
  }

  func isCacheable(_ route: Route) -> Bool {
    if case .sabrTrack = route.target {
      return false
    }
    return true
  }

  func isLocalURL(_ url: URL) -> Bool {
    guard let localPort else { return false }
    return url.scheme == "http"
      && url.host == "127.0.0.1"
      && url.port == Int(localPort.rawValue)
  }
}
