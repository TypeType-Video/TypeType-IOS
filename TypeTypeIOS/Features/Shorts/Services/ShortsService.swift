import Foundation

protocol ShortsServiceProtocol {
  func recommendations(serviceID: Int, cursor: String?, limit: Int) async throws -> HomeRecommendationsResponse
  func subscriptionShorts(page: Int, limit: Int, serviceID: Int, blended: Bool) async throws -> ShortsFeedPage
}

struct HomeRecommendationsResponse: Decodable {
  let items: [HomeVideoItem]
  let nextCursor: String?
  let hasMore: Bool
}

final class ShortsService: ShortsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func recommendations(serviceID: Int, cursor: String?, limit: Int = 30) async throws -> HomeRecommendationsResponse {
    var query = [
      URLQueryItem(name: "service", value: "\(serviceID)"),
      URLQueryItem(name: "limit", value: "\(limit)"),
      URLQueryItem(name: "intent", value: "quick"),
    ]
    if let cursor, !cursor.isEmpty {
      query.append(URLQueryItem(name: "cursor", value: cursor))
    }
    let endpoint = APIEndpoint(path: "/recommendations/shorts", method: .get, queryItems: query, requiresAuth: true)
    return try await apiClient.request(endpoint, as: HomeRecommendationsResponse.self)
  }

  func subscriptionShorts(
    page: Int,
    limit: Int = 30,
    serviceID: Int,
    blended: Bool = true
  ) async throws -> ShortsFeedPage {
    let endpoint = APIEndpoint(
      path: "/subscriptions/shorts",
      method: .get,
      queryItems: [
        URLQueryItem(name: "page", value: "\(max(0, page))"),
        URLQueryItem(name: "limit", value: "\(max(1, limit))"),
        URLQueryItem(name: "service", value: "\(serviceID)"),
        URLQueryItem(name: "blended", value: blended ? "true" : "false"),
      ],
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: ShortsFeedPage.self)
  }
}
