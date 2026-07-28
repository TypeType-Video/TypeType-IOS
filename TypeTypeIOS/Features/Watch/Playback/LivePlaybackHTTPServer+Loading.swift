import Foundation

extension LivePlaybackHTTPServer {
  func load(_ route: Route) async throws -> Resource {
    let cacheKey = cacheKey(for: route)
    if isCacheable(route),
      let cached = cache.object(forKey: cacheKey) {
      return Resource(
        data: cached as Data,
        mimeType: mimeType(for: route)
      )
    }

    let resource: Resource
    switch route.target {
    case let .upstream(url):
      resource = try await loadUpstream(url)
    case .sabrMaster:
      resource = try await loadSABRMaster()
    case let .sabrTrack(kind):
      resource = try await loadSABRTrack(kind)
    case .providerMaster:
      resource = Resource(
        data: Data(try providerMasterPlaylist().utf8),
        mimeType: Self.playlistMIME
      )
    case let .subtitlePlaylist(index):
      guard preparation.subtitles.indices.contains(index) else {
        throw LivePlaybackFailure.invalidServerResource
      }
      resource = Resource(
        data: Data(subtitlePlaylist(index: index).utf8),
        mimeType: Self.playlistMIME
      )
    case let .subtitleVTT(index):
      guard preparation.subtitles.indices.contains(index) else {
        throw LivePlaybackFailure.invalidServerResource
      }
      let data = try await service.subtitleData(
        for: preparation.subtitles[index]
      )
      resource = Resource(
        data: normalizedVTT(data),
        mimeType: "text/vtt"
      )
    }
    if isCacheable(route) {
      cache.setObject(
        resource.data as NSData,
        forKey: cacheKey,
        cost: resource.data.count
      )
    }
    return resource
  }

  private func loadUpstream(_ url: URL) async throws -> Resource {
    for attempt in 0..<Self.sabrResourcePollLimit {
      try Task.checkCancellation()
      let data = try await service.resourceData(for: url)
      if let retryAfter = sabrRetryDelay(
        for: data,
        upstreamURL: url
      ) {
        guard attempt + 1 < Self.sabrResourcePollLimit else {
          throw LivePlaybackFailure.sabrSessionTimedOut
        }
        try await Task.sleep(for: .milliseconds(retryAfter))
        continue
      }
      if isPlaylist(data) {
        return Resource(
          data: try rewritePlaylist(data, upstreamURL: url),
          mimeType: Self.playlistMIME
        )
      }
      return Resource(
        data: data,
        mimeType: upstreamMIMEType(for: url)
      )
    }
    throw LivePlaybackFailure.sabrSessionTimedOut
  }

  private func sabrRetryDelay(
    for data: Data,
    upstreamURL: URL
  ) -> Int? {
    guard upstreamURL.scheme == LivePlaybackService.authenticatedScheme,
      upstreamURL.path.contains("/sabr/playback/"),
      let response = try? JSONSerialization.jsonObject(with: data)
        as? [String: Any],
      response["ready"] as? Bool == false
    else {
      return nil
    }
    let requested = response["retryAfterMs"] as? NSNumber
    return min(max(requested?.intValue ?? 500, 50), 2_000)
  }

  private static let sabrResourcePollLimit = 120
}
