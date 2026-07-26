import Foundation

protocol HomeFeedServiceProtocol {
  func recommendations(
    serviceID: Int,
    intent: String,
    limit: Int,
    cursor: String?
  ) async throws -> HomeRecommendationsPage
}

final class HomeFeedService: HomeFeedServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func recommendations(
    serviceID: Int,
    intent: String = "auto",
    limit: Int = 30,
    cursor: String? = nil
  ) async throws -> HomeRecommendationsPage {
    var queryItems = [
      URLQueryItem(name: "service", value: String(serviceID)),
      URLQueryItem(
        name: "limit",
        value: String(min(max(limit, 1), 60))
      ),
      URLQueryItem(name: "intent", value: intent),
    ]
    if let cursor, !cursor.isEmpty {
      queryItems.append(
        URLQueryItem(name: "cursor", value: cursor)
      )
    }
    return try await apiClient.request(
      APIEndpoint(
        path: "/recommendations/home",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true
      ),
      as: HomeRecommendationsPage.self
    )
  }
}
