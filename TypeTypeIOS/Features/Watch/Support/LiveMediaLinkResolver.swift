import Foundation

enum LiveMediaLinkDestination {
  case video(LiveVideoItem)
  case channel(String)
  case playlist(LivePlaylistResult)
  case twitch(LiveTwitchLink)
}

enum LiveMediaLinkResolver {
  static func destination(
    for url: URL,
    serverURL: URL? = nil
  ) -> LiveMediaLinkDestination? {
    if let twitch = twitchDestination(for: url) { return twitch }
    let isOwnLink = url.scheme?.lowercased() == "typetype"
      || serverURL.map { sameOrigin(url, $0) } == true
    if isOwnLink {
      return typeTypeDestination(for: url) ?? providerDestination(for: url)
    }
    return providerDestination(for: url) ?? typeTypeDestination(for: url)
  }

  // Any instance's link opens here: its v, list or url value names the provider media, not the instance.
  private static func typeTypeDestination(
    for url: URL
  ) -> LiveMediaLinkDestination? {
    let scheme = url.scheme?.lowercased()
    let isCustomScheme = scheme == "typetype"
    guard isCustomScheme || scheme == "http" || scheme == "https" else {
      return nil
    }

    let components = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    )
    let route: String
    if isCustomScheme, let host = url.host, !host.isEmpty {
      route = host.lowercased()
    } else {
      route = url.pathComponents
        .last(where: { $0 != "/" })?
        .lowercased() ?? ""
    }
    let query = components?.queryItems?.reduce(
      into: [String: String]()
    ) { values, item in
      guard let value = item.value, values[item.name] == nil else {
        return
      }
      values[item.name] = value
    } ?? [:]

    switch route {
    case "watch", "shorts":
      return query["v"].flatMap(videoDestination(for:))
    case "channel":
      return query["url"].flatMap(channelDestination(for:))
    case "playlist":
      if let value = query["url"] {
        return playlistDestination(for: value)
      }
      return query["list"].flatMap(playlistDestination(forListID:))
    case "open":
      guard let value = query["url"],
        let nestedURL = URL(string: value),
        nestedURL != url
      else {
        return nil
      }
      return twitchDestination(for: nestedURL) ?? providerDestination(for: nestedURL)
    default:
      return nil
    }
  }

  // A Twitch channel opens its page; a past broadcast or a clip plays like any video.
  private static func twitchDestination(for url: URL) -> LiveMediaLinkDestination? {
    switch LiveTwitchLink.target(for: url) {
    case let .channel(login)?: .twitch(.channel(login))
    case let link?: .video(LiveTwitchPlayback.item(for: link))
    case nil: nil
    }
  }
}
