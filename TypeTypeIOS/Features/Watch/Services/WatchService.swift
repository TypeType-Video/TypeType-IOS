import Foundation

protocol WatchServiceProtocol {
  func stream(for videoURL: String) async throws -> WatchStream
}

final class WatchService: WatchServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func stream(for videoURL: String) async throws -> WatchStream {
    let endpoint = APIEndpoint(
      path: "/streams",
      method: .get,
      queryItems: [URLQueryItem(name: "url", value: videoURL)]
    )
    return try await apiClient.request(endpoint, as: WatchStream.self)
  }
}
