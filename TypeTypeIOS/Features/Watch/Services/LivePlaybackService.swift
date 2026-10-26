import Foundation

protocol LivePlaybackServiceProtocol: AnyObject {
  func stream(for videoURL: String) async throws -> LivePlaybackStream
  func playbackStream(for videoURL: String) async throws -> LivePlaybackStream
  func prepare(
    stream: LivePlaybackStream,
    sourceURL: String,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation
  func resourceData(for assetURL: URL) async throws -> Data
  func resourceData(
    for assetURL: URL,
    range: ClosedRange<Int>
  ) async throws -> Data
  func subtitleData(for source: LivePlaybackSubtitle) async throws -> Data
  func preconnectMedia()
  func prewarmSABRPlayback(videoID: String, request: LiveSABRPlaybackRequest) async
  func createSABRPlayback(
    videoID: String,
    request: LiveSABRPlaybackRequest
  ) async throws -> LiveSABRPlaybackControl
  func seekSABRPlayback(
    sessionID: String,
    request: LiveSABRPlaybackRequest
  ) async throws -> LiveSABRPlaybackControl
  func prefetchSABRPlayback(
    sessionID: String,
    request: LiveSABRWindowRequest
  ) async throws -> LiveSABRWindowResponse
  func loadSABRSegments(
    sessionID: String,
    request: LiveSABRWindowRequest
  ) async throws -> LiveSABRWindowResponse
  func updateSABRPosition(
    sessionID: String,
    request: LiveSABRPositionRequest
  ) async throws -> LiveSABRPositionResponse
  func loadSABRIndex(
    videoID: String,
    sessionID: String
  ) async throws -> LiveSABRPlaybackIndex
  func authenticatedSABRResourceURL(
    for value: String
  ) throws -> URL
  func bulletComments(
    for videoURL: String
  ) async throws -> [LiveBulletComment]
}

extension LivePlaybackServiceProtocol {
  func resourceData(
    for assetURL: URL,
    range: ClosedRange<Int>
  ) async throws -> Data {
    try await resourceData(for: assetURL)
  }

  func bulletComments(
    for videoURL: String
  ) async throws -> [LiveBulletComment] {
    []
  }

  func preconnectMedia() {}

  func prewarmSABRPlayback(videoID: String, request: LiveSABRPlaybackRequest) async {}
}

final class LivePlaybackService: LivePlaybackServiceProtocol {
  let apiClient: APIClient
  let serverURLProvider: () -> URL?

  init(
    apiClient: APIClient,
    serverURLProvider: @escaping () -> URL?
  ) {
    self.apiClient = apiClient
    self.serverURLProvider = serverURLProvider
  }

  /// Stream metadata is stable for minutes: reopening a video or advancing
  /// the queue re-uses the last response instead of re-fetching.
  let streamCache = LiveStreamMetadataCache()
  /// Playback-only bootstrap responses, kept apart from full metadata.
  let playbackCache = LiveStreamMetadataCache()
  static let streamCacheTTL: TimeInterval = 600
  let requests = LiveStreamRequests()
  let preconnector = LiveMediaPreconnector()
  let prewarms = LiveSABRPrewarms()

  func stream(for videoURL: String) async throws -> LivePlaybackStream {
    if let cached = streamCache.stream(
      for: videoURL,
      ttl: Self.streamCacheTTL
    ) {
      return cached
    }
    let loaded = try await requests.value(for: "full|" + videoURL) { [self] in
      try await loadStream(for: videoURL)
    }
    // Live manifests are short-lived and the live edge moves: never reuse them.
    if !loaded.isLive {
      streamCache.store(loaded, for: videoURL)
    }
    return loaded
  }

  private func loadStream(for videoURL: String) async throws -> LivePlaybackStream {
    let path = streamPath(for: videoURL)
    if path == "/streams/youtube/sabr/bootstrap" {
      do {
        return try await requestStream(
          path: "/streams/youtube/sabr",
          videoURL: videoURL
        )
      } catch {
        return try await youtubeSABRStream(
          path: path,
          videoURL: videoURL,
          attempt: 0
        )
      }
    }
    return try await requestStream(path: path, videoURL: videoURL)
  }

  func requestStream(
    path: String,
    videoURL: String,
    retryToken: String? = nil,
    retriesTransientFailures: Bool = true
  ) async throws -> LivePlaybackStream {
    var queryItems = [URLQueryItem(name: "url", value: videoURL)]
    if let retryToken {
      queryItems.append(
        URLQueryItem(name: "sabrRetry", value: retryToken)
      )
    }
    return try await apiClient.request(
      APIEndpoint(
        path: path,
        method: .get,
        queryItems: queryItems,
        headers: retryToken == nil
          ? [:]
          : ["Cache-Control": "no-cache"],
        requiresAuth: true,
        timeoutInterval: 120,
        retriesTransientFailures: retriesTransientFailures
      ),
      as: LivePlaybackStream.self
    )
  }

  private func youtubeSABRStream(
    path: String,
    videoURL: String,
    attempt: Int
  ) async throws -> LivePlaybackStream {
    do {
      return try await requestStream(
        path: path,
        videoURL: videoURL,
        retryToken: attempt == 0 ? nil : UUID().uuidString
      )
    } catch {
      guard attempt < 3, isRetryableSABRBootstrap(error) else {
        throw error
      }
      let delays = [350, 750, 1_500]
      try await Task.sleep(for: .milliseconds(delays[attempt]))
      return try await youtubeSABRStream(
        path: path,
        videoURL: videoURL,
        attempt: attempt + 1
      )
    }
  }

  private func isRetryableSABRBootstrap(_ error: Error) -> Bool {
    guard let networkError = error as? NetworkError else { return false }
    switch networkError {
    case let .statusCode(code, message):
      if [502, 503, 504].contains(code) { return true }
      return code == 422
        && message?.localizedCaseInsensitiveContains(
          "SABR bootstrap metadata unavailable"
        ) == true
    case .transport:
      return true
    default:
      return false
    }
  }

  func prepare(
    stream: LivePlaybackStream,
    sourceURL: String,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    if isYouTubeURL(sourceURL), Self.playsAsLiveHLS(stream) {
      return try prepareLiveHLS(stream: stream, preferences: preferences)
    }
    if isYouTubeURL(sourceURL) {
      return try prepareYouTubeSABR(
        stream: stream,
        preferences: preferences
      )
    }
    return try prepareProviderPlayback(
      stream: stream,
      preferences: preferences
    )
  }
}
