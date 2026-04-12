import Foundation

protocol SearchServiceProtocol {
  func search(query: String, serviceID: Int, nextPage: String?) async throws -> SearchPageResult
  func suggestions(query: String, serviceID: Int) async throws -> [String]
  func searchHistory(page: Int, limit: Int) async throws -> [SearchHistoryItem]
  func addSearchHistory(term: String) async throws
  func clearSearchHistory() async throws
}

final class SearchService: SearchServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func search(query: String, serviceID: Int, nextPage: String?) async throws -> SearchPageResult {
    var params = [
      URLQueryItem(name: "q", value: query),
      URLQueryItem(name: "service", value: "\(serviceID)"),
    ]
    if let nextPage, !nextPage.isEmpty {
      params.append(URLQueryItem(name: "nextpage", value: nextPage))
    }
    let endpoint = APIEndpoint(path: "/search", method: .get, queryItems: params)
    return try await apiClient.request(endpoint, as: SearchPageResult.self)
  }

  func suggestions(query: String, serviceID: Int) async throws -> [String] {
    let endpoint = APIEndpoint(
      path: "/suggestions",
      method: .get,
      queryItems: [
        URLQueryItem(name: "query", value: query),
        URLQueryItem(name: "service", value: "\(serviceID)"),
      ]
    )
    return try await apiClient.request(endpoint, as: [String].self)
  }

  func searchHistory(page: Int, limit: Int) async throws -> [SearchHistoryItem] {
    let endpoint = APIEndpoint(
      path: "/search-history",
      method: .get,
      queryItems: [
        URLQueryItem(name: "page", value: "\(max(1, page))"),
        URLQueryItem(name: "limit", value: "\(max(1, limit))"),
      ],
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: [SearchHistoryItem].self)
  }

  func addSearchHistory(term: String) async throws {
    struct Payload: Encodable { let term: String }
    let endpoint = APIEndpoint(
      path: "/search-history",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(Payload(term: term)),
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func clearSearchHistory() async throws {
    let endpoint = APIEndpoint(path: "/search-history", method: .delete, requiresAuth: true)
    try await apiClient.request(endpoint)
  }
}
