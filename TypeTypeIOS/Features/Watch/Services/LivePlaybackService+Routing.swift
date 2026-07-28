import Foundation

extension LivePlaybackService {
  func streamPath(for rawURL: String) -> String {
    if isYouTubeURL(rawURL) {
      return "/streams/youtube/sabr/bootstrap"
    }
    guard let host = URL(string: rawURL)?.host?.lowercased() else {
      return "/streams"
    }
    if host == "nicovideo.jp" || host.hasSuffix(".nicovideo.jp")
      || host == "nico.ms" {
      return "/streams/niconico"
    }
    if host == "bilibili.com" || host.hasSuffix(".bilibili.com")
      || host == "b23.tv" {
      return "/streams/bilibili"
    }
    return "/streams"
  }

  func isYouTubeURL(_ rawURL: String) -> Bool {
    guard let host = URL(string: rawURL)?.host?.lowercased() else {
      return false
    }
    return host == "youtu.be" || host == "youtube.com"
      || host.hasSuffix(".youtube.com")
      || host == "youtube-nocookie.com"
      || host.hasSuffix(".youtube-nocookie.com")
  }

  func serverEndpoint(for assetURL: URL) throws -> APIEndpoint {
    guard assetURL.scheme == Self.authenticatedScheme,
      let serverURL = serverURLProvider(),
      let components = URLComponents(
        url: assetURL,
        resolvingAgainstBaseURL: false
      )
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    guard components.host?.caseInsensitiveCompare(
      serverURL.host ?? ""
    ) == .orderedSame,
      components.port == serverURL.port
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    let serverPath = serverURL.path.hasSuffix("/")
      ? String(serverURL.path.dropLast())
      : serverURL.path
    guard components.path == serverPath
      || components.path.hasPrefix("\(serverPath)/")
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    let relativePath = String(components.path.dropFirst(serverPath.count))
    return APIEndpoint(
      path: relativePath.isEmpty ? "/" : relativePath,
      method: .get,
      queryItems: components.queryItems ?? [],
      requiresAuth: true,
      timeoutInterval: 180
    )
  }

  func authenticatedAssetURL(for url: URL) -> URL {
    guard var components = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    ) else {
      return url
    }
    components.scheme = Self.authenticatedScheme
    return components.url ?? url
  }

  func isSelectedServerURL(_ url: URL) -> Bool {
    guard let serverURL = serverURLProvider() else { return false }
    return url.scheme?.caseInsensitiveCompare(
      serverURL.scheme ?? ""
    ) == .orderedSame
      && url.host?.caseInsensitiveCompare(
        serverURL.host ?? ""
      ) == .orderedSame
      && url.port == serverURL.port
      && (url.path == serverURL.path
        || url.path.hasPrefix(
          serverURL.path.hasSuffix("/")
            ? serverURL.path
            : "\(serverURL.path)/"
        ))
  }

  static let authenticatedScheme = "typetype-sabr"
}
