import Foundation

extension LivePlaybackHTTPServer {
  func load(_ route: Route) async throws -> Resource {
    let cacheKey = cacheKey(for: route) as String
    if let cached = cachedResource(for: route, key: cacheKey) {
      return cached
    }
    return try await loadCoordinator.value(
      for: cacheKey
    ) { [weak self] in
      guard let self else { throw CancellationError() }
      return try await LivePlaybackDebugTrace.measure("proxy \(route.debugName)") {
        try await self.loadResource(route, cacheKey: cacheKey)
      }
    }
  }

  private func loadResource(
    _ route: Route,
    cacheKey: String
  ) async throws -> Resource {
    if let cached = cachedResource(for: route, key: cacheKey) {
      return cached
    }

    let resource: Resource
    switch route.target {
    case let .upstream(url):
      resource = try await loadUpstream(url)
    case let .upstreamRange(url, range, mimeType):
      resource = Resource(
        data: try await loadProviderRange(url, range: range),
        mimeType: mimeType
      )
    case .sabrMaster:
      resource = try await loadSABRMaster()
    case let .sabrTrack(kind):
      resource = try await loadSABRTrack(kind)
    case .providerMaster:
      let playlist = try providerProgressiveMaster
        ?? providerMasterPlaylist()
      resource = Resource(
        data: Data(playlist.utf8),
        mimeType: Self.playlistMIME
      )
    case .providerProgressiveVideo:
      guard let providerProgressiveVideo else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      resource = Resource(
        data: Data(providerProgressiveVideo.utf8),
        mimeType: Self.playlistMIME
      )
    case .providerProgressiveAudio:
      guard let providerProgressiveAudio else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      resource = Resource(
        data: Data(providerProgressiveAudio.utf8),
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
      let data: Data
      do {
        data = try await service.subtitleData(
          for: preparation.subtitles[index]
        )
      } catch {
        let failure = error as NSError
        AppLogger.app.error(
          "Subtitle resource failed without interrupting playback: \(failure.domain, privacy: .public) \(failure.code) \(failure.localizedDescription, privacy: .public)"
        )
        data = Data("WEBVTT\n\n".utf8)
      }
      resource = Resource(
        data: normalizedVTT(data),
        mimeType: "text/vtt"
      )
    }
    cacheResource(resource, for: route, key: cacheKey)
    return resource
  }

  private func cachedResource(
    for route: Route,
    key: String
  ) -> Resource? {
    guard isCacheable(route),
      let cached = cache.object(forKey: key as NSString)
    else {
      return nil
    }
    return Resource(
      data: cached as Data,
      mimeType: mimeType(for: route)
    )
  }

  private func cacheResource(
    _ resource: Resource,
    for route: Route,
    key: String
  ) {
    guard isCacheable(route) else { return }
    cache.setObject(
      resource.data as NSData,
      forKey: key as NSString,
      cost: resource.data.count
    )
  }
}
