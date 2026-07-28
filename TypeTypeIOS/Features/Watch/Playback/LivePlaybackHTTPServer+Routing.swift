import Foundation

extension LivePlaybackHTTPServer {
  func register(
    target: Target,
    pathExtension: String
  ) -> String {
    if case let .upstream(url) = target,
      let existing = lock.withLock({
        upstreamRouteIDs[url]
      }) {
      return existing
    }
    let identifier = UUID().uuidString.lowercased()
    lock.withLock {
      routes[identifier] = Route(
        target: target,
        pathExtension: pathExtension
      )
      if case let .upstream(url) = target {
        upstreamRouteIDs[url] = identifier
      }
    }
    return identifier
  }

  func route(for path: String) -> Route? {
    guard path.hasPrefix("/resource/") else { return nil }
    let file = String(path.dropFirst("/resource/".count))
    let identifier = String(file.split(separator: ".").first ?? "")
    return lock.withLock { routes[identifier] }
  }

  func localURL(
    routeID: String,
    extension pathExtension: String
  ) -> URL? {
    guard let port = localPort else { return nil }
    return URL(
      string: "http://127.0.0.1:\(port.rawValue)"
        + "/resource/\(routeID).\(pathExtension)"
    )
  }

  func cacheKey(for route: Route) -> NSString {
    switch route.target {
    case let .upstream(url):
      return "upstream:\(url.absoluteString)" as NSString
    case .sabrMaster:
      return "sabr-master" as NSString
    case let .sabrTrack(kind):
      return "sabr-track:\(String(describing: kind))" as NSString
    case .providerMaster:
      return "provider-master" as NSString
    case let .subtitlePlaylist(index):
      return "subtitle-playlist:\(index)" as NSString
    case let .subtitleVTT(index):
      return "subtitle-vtt:\(index)" as NSString
    }
  }
}
