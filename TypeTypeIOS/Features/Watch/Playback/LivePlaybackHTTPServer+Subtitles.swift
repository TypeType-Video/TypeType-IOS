import Foundation

extension LivePlaybackHTTPServer {
  func subtitlePlaylist(index: Int) -> String {
    let targetDuration = max(
      Int(ceil(TimeInterval(preparation.stream.duration))),
      1
    )
    let routeID = register(
      target: .subtitleVTT(index),
      pathExtension: "vtt"
    )
    let url = localURL(routeID: routeID, extension: "vtt")
    return """
      #EXTM3U
      #EXT-X-VERSION:7
      #EXT-X-TARGETDURATION:\(targetDuration)
      #EXT-X-MEDIA-SEQUENCE:0
      #EXT-X-PLAYLIST-TYPE:VOD
      #EXTINF:\(String(format: "%.3f", preparation.stream.duration)),
      \(url?.absoluteString ?? "")
      #EXT-X-ENDLIST

      """
  }

  func normalizedVTT(_ data: Data) -> Data {
    guard var source = String(data: data, encoding: .utf8) else {
      return data
    }
    if !source.hasPrefix("WEBVTT") {
      source = "WEBVTT\n\n\(source)"
    }
    if !source.contains("X-TIMESTAMP-MAP") {
      let line = "X-TIMESTAMP-MAP=LOCAL:00:00:00.000,MPEGTS:0\n"
      if let marker = source.range(of: "\n") {
        source.insert(contentsOf: "\n\(line)", at: marker.upperBound)
      } else {
        source += "\n\n\(line)"
      }
    }
    return Data(source.utf8)
  }

  var preferredSubtitleIndex: Int {
    guard !preferredSubtitleLanguage.isEmpty else { return 0 }
    return preparation.subtitles.firstIndex {
      $0.languageTag.caseInsensitiveCompare(
        preferredSubtitleLanguage
      ) == .orderedSame
        || $0.languageTag.lowercased().hasPrefix(
          preferredSubtitleLanguage.lowercased()
        )
    } ?? 0
  }

  func hlsQuoted(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\r", with: " ")
  }
}
