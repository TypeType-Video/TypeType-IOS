import Foundation

protocol LiveDeArrowServiceProtocol {
  func item(videoID: String) async throws -> LiveDeArrowItem
  func absoluteURL(_ value: String?) -> URL?
  func thumbnailURL(videoID: String, time: Double) -> URL?
}

final class LiveDeArrowService: LiveDeArrowServiceProtocol {
  private let apiClient: APIClient
  private let baseURLProvider: () -> URL?

  init(
    apiClient: APIClient,
    baseURLProvider: @escaping () -> URL?
  ) {
    self.apiClient = apiClient
    self.baseURLProvider = baseURLProvider
  }

  func item(videoID: String) async throws -> LiveDeArrowItem {
    try await apiClient.request(
      APIEndpoint(
        path: "/dearrow",
        method: .get,
        queryItems: [
          URLQueryItem(name: "videoId", value: videoID),
        ],
        requiresAuth: true
      ),
      as: LiveDeArrowItem.self
    )
  }

  func absoluteURL(_ value: String?) -> URL? {
    guard let value, !value.isEmpty else { return nil }
    if let url = URL(string: value), url.scheme != nil {
      return url
    }
    return endpointURL(path: value)
  }

  func thumbnailURL(videoID: String, time: Double) -> URL? {
    endpointURL(
      path: "/dearrow/thumbnail",
      queryItems: [
        URLQueryItem(name: "videoId", value: videoID),
        URLQueryItem(name: "time", value: String(time)),
      ]
    )
  }

  private func endpointURL(
    path: String,
    queryItems: [URLQueryItem] = []
  ) -> URL? {
    guard let baseURL = baseURLProvider(),
      var components = URLComponents(
        url: baseURL,
        resolvingAgainstBaseURL: false
      )
    else {
      return nil
    }
    let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
    let basePath = components.path.hasSuffix("/")
      ? String(components.path.dropLast())
      : components.path
    components.path = "\(basePath)\(normalizedPath)"
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    components.fragment = nil
    return components.url
  }
}
