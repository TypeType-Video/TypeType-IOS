import Foundation

protocol LivePlaybackServiceProtocol: AnyObject {
  func stream(for videoURL: String) async throws -> LivePlaybackStream
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

  func stream(for videoURL: String) async throws -> LivePlaybackStream {
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

  private func requestStream(
    path: String,
    videoURL: String,
    retryToken: String? = nil
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
        timeoutInterval: 120
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

  func resourceData(for assetURL: URL) async throws -> Data {
    let endpoint = try serverEndpoint(for: assetURL)
    return try await apiClient.requestData(endpoint)
  }

  func resourceData(
    for assetURL: URL,
    range: ClosedRange<Int>
  ) async throws -> Data {
    let endpoint = try serverEndpoint(for: assetURL)
    return try await apiClient.requestData(
      APIEndpoint(
        path: endpoint.path,
        method: endpoint.method,
        queryItems: endpoint.queryItems,
        headers: [
          "Range": "bytes=\(range.lowerBound)-\(range.upperBound)"
        ],
        body: endpoint.body,
        requiresAuth: endpoint.requiresAuth,
        timeoutInterval: endpoint.timeoutInterval
      )
    )
  }

  func subtitleData(for source: LivePlaybackSubtitle) async throws -> Data {
    guard let sourceURL = URL(string: source.url) else {
      throw LivePlaybackFailure.invalidServerResource
    }
    if isSelectedServerURL(sourceURL) {
      return try await resourceData(
        for: authenticatedAssetURL(for: sourceURL)
      )
    }
    guard var components = URLComponents(
      url: sourceURL,
      resolvingAgainstBaseURL: false
    ) else {
      throw LivePlaybackFailure.invalidServerResource
    }
    var items = components.queryItems ?? []
    if !items.contains(where: { $0.name == "fmt" }) {
      items.append(URLQueryItem(name: "fmt", value: "vtt"))
      components.queryItems = items
    }
    guard let vttURL = components.url else {
      throw LivePlaybackFailure.invalidServerResource
    }
    return try await apiClient.requestData(
      APIEndpoint(
        path: "/proxy",
        method: .get,
        queryItems: [
          URLQueryItem(name: "url", value: vttURL.absoluteString)
        ],
        requiresAuth: true,
        timeoutInterval: 120
      )
    )
  }
}
