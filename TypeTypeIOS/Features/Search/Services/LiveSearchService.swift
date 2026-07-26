import Foundation

protocol LiveSearchServiceProtocol {
  func filters(serviceID: Int) async throws -> LiveSearchFilters
  func suggestions(
    query: String,
    serviceID: Int
  ) async throws -> [String]
  func trending(serviceID: Int) async throws -> [LiveVideoItem]
  func search(
    query: String,
    serviceID: Int,
    nextPage: String?,
    contentFilter: String?,
    sortFilter: String?
  ) async throws -> LiveSearchPage
}

final class LiveSearchService: LiveSearchServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func filters(serviceID: Int) async throws -> LiveSearchFilters {
    try await apiClient.request(
      APIEndpoint(
        path: "/search/filters",
        method: .get,
        queryItems: [
          URLQueryItem(name: "service", value: String(serviceID)),
        ],
        requiresAuth: true
      ),
      as: LiveSearchFilters.self
    )
  }

  func suggestions(
    query: String,
    serviceID: Int
  ) async throws -> [String] {
    try await apiClient.request(
      APIEndpoint(
        path: "/suggestions",
        method: .get,
        queryItems: [
          URLQueryItem(name: "query", value: query),
          URLQueryItem(name: "service", value: String(serviceID)),
        ],
        requiresAuth: true
      ),
      as: [String].self
    )
  }

  func trending(serviceID: Int) async throws -> [LiveVideoItem] {
    try await apiClient.request(
      APIEndpoint(
        path: "/trending",
        method: .get,
        queryItems: [
          URLQueryItem(name: "service", value: String(serviceID)),
        ],
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: [LiveVideoItem].self
    )
  }

  func search(
    query: String,
    serviceID: Int,
    nextPage: String? = nil,
    contentFilter: String? = nil,
    sortFilter: String? = nil
  ) async throws -> LiveSearchPage {
    var queryItems = [
      URLQueryItem(name: "q", value: query),
      URLQueryItem(name: "service", value: String(serviceID)),
    ]
    queryItems.appendIfPresent(name: "nextpage", value: nextPage)
    queryItems.appendIfPresent(
      name: "contentFilter",
      value: contentFilter
    )
    queryItems.appendIfPresent(name: "sortFilter", value: sortFilter)
    return try await apiClient.request(
      APIEndpoint(
        path: "/search",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LiveSearchPage.self
    )
  }
}

private extension Array where Element == URLQueryItem {
  mutating func appendIfPresent(name: String, value: String?) {
    guard let value, !value.isEmpty else { return }
    append(URLQueryItem(name: name, value: value))
  }
}
