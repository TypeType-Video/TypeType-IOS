import Foundation

protocol HomeFeedServiceProtocol {
  func trending(serviceID: Int) async throws -> [HomeVideoItem]
}

final class HomeFeedService: HomeFeedServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
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
