import Foundation

extension LivePlaybackService {
  func createSABRPlayback(
    videoID: String,
    request: LiveSABRPlaybackRequest
  ) async throws -> LiveSABRPlaybackControl {
    await prewarms.settle(LiveSABRPrewarms.Key(videoID: videoID, request: request))
    return try await sabrRequest(
      APIEndpoint(
        path: "/sabr/playback/\(videoID)",
        method: .post,
        headers: Self.playbackTraceHeader(videoID: videoID, request: request),
        body: try APIEndpoint.jsonBody(request),
        requiresAuth: true,
        timeoutInterval: 150
      ),
      as: LiveSABRPlaybackControl.self
    )
  }

  func prewarmSABRPlayback(
    videoID: String,
    request: LiveSABRPlaybackRequest
  ) async {
    guard let body = try? APIEndpoint.jsonBody(request) else { return }
    let endpoint = APIEndpoint(
      path: "/sabr/playback/\(videoID)",
      method: .post,
      queryItems: [URLQueryItem(name: "prewarm", value: "true")],
      headers: Self.playbackTraceHeader(videoID: videoID, request: request),
      body: body,
      requiresAuth: true,
      timeoutInterval: 30,
      retriesTransientFailures: false
    )
    let key = LiveSABRPrewarms.Key(videoID: videoID, request: request)
    await prewarms.prewarm(key) { [apiClient] in
      _ = try? await apiClient.requestData(endpoint)
    }
  }

  func seekSABRPlayback(
    sessionID: String,
    request: LiveSABRPlaybackRequest
  ) async throws -> LiveSABRPlaybackControl {
    try await sabrRequest(
      APIEndpoint(
        path: "/sabr/playback/\(sessionID)/seek",
        method: .post,
        body: try APIEndpoint.jsonBody(request),
        requiresAuth: true,
        timeoutInterval: 150
      ),
      as: LiveSABRPlaybackControl.self
    )
  }

  func prefetchSABRPlayback(
    sessionID: String,
    request: LiveSABRWindowRequest
  ) async throws -> LiveSABRWindowResponse {
    try await sabrRequest(
      APIEndpoint(
        path: "/sabr/playback/\(sessionID)/prefetch",
        method: .post,
        body: try APIEndpoint.jsonBody(request),
        requiresAuth: true,
        timeoutInterval: 150
      ),
      as: LiveSABRWindowResponse.self
    )
  }

  func loadSABRSegments(
    sessionID: String,
    request: LiveSABRWindowRequest
  ) async throws -> LiveSABRWindowResponse {
    try await sabrRequest(
      APIEndpoint(
        path: "/sabr/playback/\(sessionID)/segments",
        method: .post,
        body: try APIEndpoint.jsonBody(request),
        requiresAuth: true,
        timeoutInterval: 150
      ),
      as: LiveSABRWindowResponse.self
    )
  }

  func updateSABRPosition(
    sessionID: String,
    request: LiveSABRPositionRequest
  ) async throws -> LiveSABRPositionResponse {
    try await sabrRequest(
      APIEndpoint(
        path: "/sabr/playback/\(sessionID)/position",
        method: .post,
        body: try APIEndpoint.jsonBody(request),
        requiresAuth: true,
        timeoutInterval: 30
      ),
      as: LiveSABRPositionResponse.self
    )
  }

  func loadSABRIndex(
    videoID: String,
    sessionID: String
  ) async throws -> LiveSABRPlaybackIndex {
    try await sabrRequest(
      APIEndpoint(
        path: "/sabr/session/\(videoID)/state",
        method: .get,
        queryItems: [
          URLQueryItem(name: "session", value: sessionID)
        ],
        requiresAuth: true,
        timeoutInterval: 30
      ),
      as: LiveSABRPlaybackIndex.self
    )
  }

  func authenticatedSABRResourceURL(
    for value: String
  ) throws -> URL {
    guard let serverURL = serverURLProvider(),
      var server = URLComponents(
        url: serverURL,
        resolvingAgainstBaseURL: false
      ),
      let resource = URLComponents(string: value)
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    if let scheme = resource.scheme, !scheme.isEmpty {
      guard let url = resource.url, isSelectedServerURL(url) else {
        throw LivePlaybackFailure.invalidServerResource
      }
      return authenticatedAssetURL(for: url)
    }
    if value.hasPrefix("/") {
      server.path = resource.path
    } else {
      let base = server.path.hasSuffix("/")
        ? server.path
        : "\(server.path)/"
      server.path = "\(base)\(resource.path)"
    }
    server.queryItems = resource.queryItems
    guard let url = server.url, isSelectedServerURL(url) else {
      throw LivePlaybackFailure.invalidServerResource
    }
    return authenticatedAssetURL(for: url)
  }

  static func playbackTraceHeader(videoID: String, request: LiveSABRPlaybackRequest) -> [String: String] {
    let safeID = videoID.filter { ($0.isASCII && ($0.isLetter || $0.isNumber)) || "._-".contains($0) }
    return ["X-Playback-Trace-ID": "ios.\(safeID).\(request.startTimeMS)"]
  }
}
