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
    if let destination = typeTypeDestination(
      for: url,
      serverURL: serverURL
    ) {
      return destination
    }
    return providerDestination(for: url)
  }

  private static func typeTypeDestination(
    for url: URL,
    serverURL: URL?
  ) -> LiveMediaLinkDestination? {
    let scheme = url.scheme?.lowercased()
    let isCustomScheme = scheme == "typetype"
    let isCurrentServer = serverURL.map {
      sameOrigin(url, $0)
    } ?? false
    guard isCustomScheme || isCurrentServer else {
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
        .first(where: { $0 != "/" })?
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
