import Foundation

/// Media bytes (segments, playlists, subtitles) go through the media session:
/// high priority, no disk cache.
extension LivePlaybackService {
  func resourceData(for assetURL: URL) async throws -> Data {
    let endpoint = try serverEndpoint(for: assetURL)
    return try await apiClient.requestData(endpoint.asMedia())
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
        timeoutInterval: endpoint.timeoutInterval,
        isMedia: true
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
