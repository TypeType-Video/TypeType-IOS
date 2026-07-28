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

  func loadProviderRange(
    _ url: URL,
    range: ClosedRange<Int>,
    allowsAdaptiveRetry: Bool = true
  ) async throws -> Data {
    let chunks = Self.providerChunkRanges(range)
    let orderedChunks = try await withThrowingTaskGroup(
      of: (Int, Data).self,
      returning: [Data].self
    ) { group in
      var nextIndex = 0
      let initialRequestCount = min(
        chunks.count,
        Self.providerConcurrentChunkLimit
      )
      for _ in 0..<initialRequestCount {
        let index = nextIndex
        let chunk = chunks[index]
        nextIndex += 1
        group.addTask { [self] in
          try await loadProviderChunk(
            url,
            range: chunk,
            index: index,
            allowsAdaptiveRetry: allowsAdaptiveRetry
          )
        }
      }

      var results = Array<Data?>(
        repeating: nil,
        count: chunks.count
      )
      while let (index, data) = try await group.next() {
        results[index] = data
        guard nextIndex < chunks.count else { continue }
        let queuedIndex = nextIndex
        let queuedChunk = chunks[queuedIndex]
        nextIndex += 1
        group.addTask { [self] in
          try await loadProviderChunk(
            url,
            range: queuedChunk,
            index: queuedIndex,
            allowsAdaptiveRetry: allowsAdaptiveRetry
          )
        }
      }

      return try results.map { data in
        guard let data else {
          throw LivePlaybackFailure.invalidPlaylist
        }
        return data
      }
    }

    var result = Data()
    result.reserveCapacity(range.upperBound - range.lowerBound + 1)
    for chunk in orderedChunks {
      result.append(chunk)
    }
    return result
  }

  private func loadProviderChunk(
    _ url: URL,
    range: ClosedRange<Int>,
    index: Int,
    allowsAdaptiveRetry: Bool
  ) async throws -> (Int, Data) {
    try Task.checkCancellation()
    let data = try await loadProviderChunkData(
      url,
      range: range,
      allowsAdaptiveRetry: allowsAdaptiveRetry
    )
    let expectedCount = range.upperBound - range.lowerBound + 1
    guard data.count == expectedCount else {
      throw LivePlaybackFailure.invalidPlaylist
    }
    return (index, data)
  }

  private func loadProviderChunkData(
    _ url: URL,
    range: ClosedRange<Int>,
    allowsAdaptiveRetry: Bool
  ) async throws -> Data {
    do {
      return try await service.resourceData(
        for: url,
        range: range
      )
    } catch {
      guard allowsAdaptiveRetry,
        shouldSplitProviderChunk(range, after: error)
      else {
        throw error
      }
      let midpoint = range.lowerBound
        + (range.upperBound - range.lowerBound) / 2
      let lowerRange = range.lowerBound...midpoint
      let upperRange = (midpoint + 1)...range.upperBound
      AppLogger.app.info(
        "Retrying truncated provider bytes \(range.lowerBound, privacy: .public)-\(range.upperBound, privacy: .public) as smaller ranges."
      )
      async let lowerData = loadProviderChunkData(
        url,
        range: lowerRange,
        allowsAdaptiveRetry: true
      )
      async let upperData = loadProviderChunkData(
        url,
        range: upperRange,
        allowsAdaptiveRetry: true
      )
      var result = try await lowerData
      result.append(try await upperData)
      return result
    }
  }

  private func shouldSplitProviderChunk(
    _ range: ClosedRange<Int>,
    after error: Error
  ) -> Bool {
    guard range.upperBound - range.lowerBound + 1
      > Self.providerMinimumRetryByteCount,
      case let NetworkError.statusCode(code, message) = error,
      code == 422
    else {
      return false
    }
    return message?.localizedCaseInsensitiveContains(
      "unexpected end of stream"
    ) == true
  }

  static func providerChunkRanges(
    _ range: ClosedRange<Int>
  ) -> [ClosedRange<Int>] {
    var chunks: [ClosedRange<Int>] = []
    var lowerBound = range.lowerBound
    while lowerBound <= range.upperBound {
      let available = range.upperBound - lowerBound
      let upperBound = lowerBound
        + min(providerChunkByteCount - 1, available)
      chunks.append(lowerBound...upperBound)
      guard upperBound < range.upperBound else { break }
      lowerBound = upperBound + 1
    }
    return chunks
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
  private static let providerChunkByteCount = 128 * 1_024
  private static let providerMinimumRetryByteCount = 16 * 1_024
  private static let providerConcurrentChunkLimit = 6
}
