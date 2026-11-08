import Foundation

enum LiveMediaLinkDestination {
  case video(LiveVideoItem)
  case channel(String)
  case playlist(LivePlaylistResult)
}

enum LiveMediaLinkResolver {
  static func destination(
    for url: URL,
    serverURL: URL? = nil
  ) -> LiveMediaLinkDestination? {
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
      return providerDestination(for: nestedURL)
    default:
      return nil
    }
  }
}
