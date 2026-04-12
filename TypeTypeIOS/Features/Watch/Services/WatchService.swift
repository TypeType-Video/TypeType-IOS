import Foundation

protocol WatchServiceProtocol {
  func stream(for videoURL: String) async throws -> WatchStream
  func comments(for videoURL: String, nextPage: String?) async throws -> WatchCommentsPage
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

  func comments(for videoURL: String, nextPage: String?) async throws -> WatchCommentsPage {
    var query = [URLQueryItem(name: "url", value: videoURL)]
    if let nextPage, !nextPage.isEmpty {
      query.append(URLQueryItem(name: "nextpage", value: nextPage))
    }
    let endpoint = APIEndpoint(path: "/comments", method: .get, queryItems: query)
    return try await apiClient.request(endpoint, as: WatchCommentsPage.self)
  }
}
