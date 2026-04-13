import Foundation

protocol HomeFeedServiceProtocol {
  func recommendations(serviceID: Int, limit: Int, nextCursor: String?) async throws -> HomeRecommendationsPage
  func trending(serviceID: Int) async throws -> [HomeVideoItem]
}

struct HomeRecommendationsPage: Decodable {
  let items: [HomeVideoItem]
  let nextCursor: String?
  let hasMore: Bool
}

final class HomeFeedService: HomeFeedServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func recommendations(
    serviceID: Int,
    limit: Int = 30,
    nextCursor: String? = nil
  ) async throws -> HomeRecommendationsPage {
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "service", value: "\(serviceID)"),
      URLQueryItem(name: "limit", value: "\(max(1, limit))"),
      URLQueryItem(name: "intent", value: "auto"),
    ]
    if let nextCursor, !nextCursor.isEmpty {
      queryItems.append(URLQueryItem(name: "nextCursor", value: nextCursor))
    }

    let endpoint = APIEndpoint(
      path: "/recommendations/home",
      method: .get,
      queryItems: queryItems,
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: HomeRecommendationsPage.self)
  }

  func trending(serviceID: Int) async throws -> [HomeVideoItem] {
    let endpoint = APIEndpoint(
      path: "/trending",
      method: .get,
      queryItems: [URLQueryItem(name: "service", value: "\(serviceID)")]
    )
    return try await apiClient.request(endpoint, as: [HomeVideoItem].self)
  }
}
