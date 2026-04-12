import Foundation

protocol HomeFeedServiceProtocol {
  func recommendations(serviceID: Int, limit: Int) async throws -> [HomeVideoItem]
  func trending(serviceID: Int) async throws -> [HomeVideoItem]
}

private struct HomeRecommendationsPage: Decodable {
  let items: [HomeVideoItem]
}

final class HomeFeedService: HomeFeedServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func recommendations(serviceID: Int, limit: Int = 30) async throws -> [HomeVideoItem] {
    let endpoint = APIEndpoint(
      path: "/recommendations/home",
      method: .get,
      queryItems: [
        URLQueryItem(name: "service", value: "\(serviceID)"),
        URLQueryItem(name: "limit", value: "\(max(1, limit))"),
        URLQueryItem(name: "intent", value: "auto"),
      ],
      requiresAuth: true
    )
    let page = try await apiClient.request(endpoint, as: HomeRecommendationsPage.self)
    return page.items
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
