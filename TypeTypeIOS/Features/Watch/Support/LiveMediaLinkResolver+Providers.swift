import Foundation

extension LiveMediaLinkResolver {
  static func providerDestination(
    for url: URL
  ) -> LiveMediaLinkDestination? {
    guard let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https",
      let host = url.host?.lowercased()
    else {
      return nil
    }

    if matches(host, domains: ["youtube.com", "youtube-nocookie.com"]) {
      return youtubeDestination(for: url)
    }
    if host == "youtu.be" {
      return videoDestination(for: url)
    }
    if matches(host, domains: ["nicovideo.jp"]) {
      return nicoNicoDestination(for: url)
    }
    if host == "nico.ms" {
      return videoDestination(for: url)
    }
    if matches(host, domains: ["bilibili.com"]) {
      return biliBiliDestination(for: url, host: host)
    }
    if host == "b23.tv" {
      return videoDestination(for: url)
    }
    return nil
  }

  private static func youtubeDestination(
    for url: URL
  ) -> LiveMediaLinkDestination? {
    let path = url.path.lowercased()
    let components = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    )
    let videoID = components?.queryItems?
      .first(where: { $0.name == "v" })?.value
    if path == "/watch", videoID?.isEmpty == false {
      return videoDestination(for: url)
    }
    if ["/shorts/", "/live/", "/embed/"].contains(where: {
      path.hasPrefix($0) && path.count > $0.count
    }) {
      return videoDestination(for: url)
    }
    if path == "/playlist"
      || components?.queryItems?.contains(where: {
        $0.name == "list" && $0.value?.isEmpty == false
      }) == true {
      return playlistDestination(for: url)
    }
    if let channelID = mentionedChannelID(in: url.path) {
      return .channel("https://www.youtube.com/channel/\(channelID)")
    }
    if path.hasPrefix("/channel/")
      || path.hasPrefix("/user/")
      || path.hasPrefix("/c/")
      || path.hasPrefix("/@") {
      return .channel(url.absoluteString)
    }
    return nil
  }

  // Descriptions can mention a channel as "/@" plus its ID; YouTube answers 404 there, but /channel/ID works.
  private static func mentionedChannelID(in path: String) -> String? {
    guard path.range(of: #"^/@UC[A-Za-z0-9_-]{22}/?$"#, options: .regularExpression) != nil else {
      return nil
    }
    return String(path.dropFirst(2).prefix(24))
  }

  private static func nicoNicoDestination(
    for url: URL
  ) -> LiveMediaLinkDestination? {
    let path = url.path.lowercased()
    if path.hasPrefix("/watch/") {
      return videoDestination(for: url)
    }
    if path.hasPrefix("/user/") || path.hasPrefix("/channel/") {
      return .channel(url.absoluteString)
    }
    if path.hasPrefix("/mylist/") {
      return playlistDestination(for: url)
    }
    return nil
  }

  private static func biliBiliDestination(
    for url: URL,
    host: String
  ) -> LiveMediaLinkDestination? {
    let path = url.path.lowercased()
    if host == "space.bilibili.com" || path.hasPrefix("/space/") {
      return .channel(url.absoluteString)
    }
    if path.hasPrefix("/video/") {
      return videoDestination(for: url)
    }
    if path.hasPrefix("/medialist/")
      || path.hasPrefix("/list/") {
      return playlistDestination(for: url)
    }
    return nil
  }

  private static func matches(
    _ host: String,
    domains: [String]
  ) -> Bool {
    domains.contains {
      host == $0 || host.hasSuffix(".\($0)")
    }
  }
}
