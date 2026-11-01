import Foundation

extension LivePlaybackHTTPServer {
  func register(
    target: Target,
    pathExtension: String
  ) -> String {
    let identifier = UUID().uuidString.lowercased()
    return lock.withLock {
      if case let .upstream(url) = target,
        let existing = upstreamRouteIDs[url] {
        return existing
      }
      routes[identifier] = Route(
        target: target,
        pathExtension: pathExtension
      )
      if case let .upstream(url) = target {
        upstreamRouteIDs[url] = identifier
        trackUpstreamMediaRoute(url)
      }
      return identifier
    }
  }

  private func trackUpstreamMediaRoute(_ url: URL) {
    guard !Self.isDynamicPlaylistURL(url) else { return }
    upstreamMediaRouteOrder.append(url)
    while upstreamMediaRouteOrder.count
      > Self.maximumUpstreamMediaRoutes {
      let evictedURL = upstreamMediaRouteOrder.removeFirst()
      guard let routeID = upstreamRouteIDs.removeValue(
        forKey: evictedURL
      ) else {
        continue
      }
      routes.removeValue(forKey: routeID)
      cache.removeObject(
        forKey: "upstream:\(evictedURL.absoluteString)" as NSString
      )
    }
  }

  func route(for path: String) -> Route? {
    guard path.hasPrefix("/resource/") else { return nil }
    let file = String(path.dropFirst("/resource/".count))
    let identifier = String(file.split(separator: ".").first ?? "")
    return lock.withLock { routes[identifier] }
  }

  func discardStaleSABRResourceRoutes() {
    loadCoordinator.cancelAll()
    let staleURLs = lock.withLock { () -> [URL] in
      let values = upstreamRouteIDs.keys.filter {
        $0.scheme == LivePlaybackService.authenticatedScheme
          && $0.path.contains("/sabr/playback/")
      }
      for url in values {
        guard let routeID = upstreamRouteIDs.removeValue(
          forKey: url
        ) else {
          continue
        }
        routes.removeValue(forKey: routeID)
      }
      let staleSet = Set(values)
      upstreamMediaRouteOrder.removeAll {
        staleSet.contains($0)
      }
      return values
    }
    for url in staleURLs {
      cache.removeObject(
        forKey: "upstream:\(url.absoluteString)" as NSString
      )
    }
  }

  func localURL(
    routeID: String,
    extension pathExtension: String
  ) -> URL? {
    guard let port = localPort else { return nil }
    return URL(
      string: "http://\(host):\(port.rawValue)"
        + "/resource/\(routeID).\(pathExtension)"
    )
  }

  func cacheKey(for route: Route) -> NSString {
    switch route.target {
    case let .upstream(url):
      return "upstream:\(url.absoluteString)" as NSString
    case let .upstreamRange(url, range, mimeType):
      return
        "upstream-range:\(url.absoluteString):\(range.lowerBound)-\(range.upperBound):\(mimeType)"
        as NSString
    case .sabrMaster:
      return "sabr-master" as NSString
    case let .sabrTrack(kind):
      return "sabr-track:\(String(describing: kind))" as NSString
    case .providerMaster:
      return "provider-master" as NSString
    case .providerProgressiveVideo:
      return "provider-progressive-video" as NSString
    case .providerProgressiveAudio:
      return "provider-progressive-audio" as NSString
    case let .subtitlePlaylist(index):
      return "subtitle-playlist:\(index)" as NSString
    case let .subtitleVTT(index):
      return "subtitle-vtt:\(index)" as NSString
    }
  }
}
