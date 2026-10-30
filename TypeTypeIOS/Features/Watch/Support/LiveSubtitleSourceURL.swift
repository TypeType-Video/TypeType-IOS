import Foundation

enum LiveSubtitleSourceURL {
  // YouTube lists its tracks with fmt=ttml: fmt must be replaced, not appended, or TTML comes back.
  static func playbackURL(for url: URL) -> URL {
    guard isYouTubeTimedText(url),
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      return url
    }
    var items = (components.queryItems ?? []).filter { $0.name != "fmt" }
    items.append(URLQueryItem(name: "fmt", value: "vtt"))
    components.queryItems = items
    return components.url ?? url
  }

  static func isYouTubeTimedText(_ url: URL) -> Bool {
    guard let host = url.host?.lowercased() else { return false }
    return (host == "youtube.com" || host.hasSuffix(".youtube.com")) && url.path == "/api/timedtext"
  }
}
