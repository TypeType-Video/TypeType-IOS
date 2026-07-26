import Foundation

protocol LiveSearchHistoryServiceProtocol {
  func history(
    page: Int,
    limit: Int
  ) async throws -> [LiveSearchHistoryItem]
  func add(term: String) async throws -> LiveSearchHistoryItem
  func clear() async throws
}

final class LiveSearchHistoryService:
  LiveSearchHistoryServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func history(
    page: Int,
    limit: Int
  ) async throws -> [LiveSearchHistoryItem] {
    try await apiClient.request(
      APIEndpoint(
        path: "/search-history",
        method: .get,
        queryItems: [
          URLQueryItem(name: "page", value: String(max(page, 1))),
          URLQueryItem(
            name: "limit",
            value: String(min(max(limit, 1), 100))
          ),
        ],
        requiresAuth: true
      ),
      as: [LiveSearchHistoryItem].self
    )
  }

  func add(term: String) async throws -> LiveSearchHistoryItem {
    try await apiClient.request(
      APIEndpoint(
        path: "/search-history",
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveSearchHistoryPayload(term: term)
        ),
        requiresAuth: true
      ),
      as: LiveSearchHistoryItem.self
    )
  }

  func clear() async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/search-history",
        method: .delete,
        requiresAuth: true
      )
    )
  }
}

private struct LiveSearchHistoryPayload: Encodable {
  let term: String
}
