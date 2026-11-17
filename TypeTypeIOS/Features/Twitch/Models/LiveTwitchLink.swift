import Foundation

enum LiveTwitchLink: Hashable, Identifiable {
  case channel(String)
  case video(String)
  case clip(String)

  var id: String {
    switch self {
    case let .channel(login): "c:\(login)"
    case let .video(id): "v:\(id)"
    case let .clip(slug): "clip:\(slug)"
    }
  }

  private static let reserved: Set<String> = [
    "videos", "directory", "search", "settings", "downloads", "p", "jobs", "turbo", "subscriptions",
  ]

  // Same rules as the web client: twitch.tv channels, past broadcasts and clips, and the instance's own /twitch pages.
  static func target(for url: URL) -> LiveTwitchLink? {
    let host = url.host?.lowercased() ?? ""
    let parts = url.pathComponents.filter { $0 != "/" }
    if host == "clips.twitch.tv" {
      return parts.count == 1 && isClip(parts[0]) ? .clip(parts[0]) : nil
    }
    if ["twitch.tv", "www.twitch.tv", "m.twitch.tv"].contains(host) {
      return provider(parts)
    }
    return instance(parts, query: query(url))
  }

  private static func provider(_ parts: [String]) -> LiveTwitchLink? {
    if parts.count == 3, parts[1] == "clip", isLogin(parts[0]), isClip(parts[2]) { return .clip(parts[2]) }
    if parts.count == 2, parts[0] == "videos", isVideo(parts[1]) { return .video(parts[1]) }
    if parts.count == 1, isLogin(parts[0]), !reserved.contains(parts[0].lowercased()) { return .channel(parts[0].lowercased()) }
    return nil
  }

  private static func instance(_ parts: [String], query: [String: String]) -> LiveTwitchLink? {
    guard parts.first == "twitch" else { return nil }
    if parts.count == 3, parts[1] == "channel", isLogin(parts[2]) { return .channel(parts[2].lowercased()) }
    guard parts.count == 2, parts[1] == "watch" else { return nil }
    if let login = query["c"], isLogin(login) { return .channel(login.lowercased()) }
    if let id = query["v"], isVideo(id) { return .video(id) }
    if let slug = query["clip"], isClip(slug) { return .clip(slug) }
    return nil
  }

  private static func query(_ url: URL) -> [String: String] {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    return items.reduce(into: [:]) { values, item in
      if values[item.name] == nil, let value = item.value { values[item.name] = value }
    }
  }

  private static func isLogin(_ value: String) -> Bool {
    (1...25).contains(value.count) && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
  }

  private static func isVideo(_ value: String) -> Bool {
    (1...20).contains(value.count) && value.allSatisfy { $0.isASCII && $0.isNumber }
  }

  private static func isClip(_ value: String) -> Bool {
    (4...100).contains(value.count) && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") }
  }
}
