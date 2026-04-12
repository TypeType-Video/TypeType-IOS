import Foundation

protocol SubscriptionsServiceProtocol {
  func channels() async throws -> [SubscriptionChannel]
  func feed(page: Int, limit: Int) async throws -> SubscriptionsFeedPage
  func deleteChannel(_ channelURL: String) async throws
}

final class SubscriptionsService: SubscriptionsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func channels() async throws -> [SubscriptionChannel] {
    let endpoint = APIEndpoint(path: "/subscriptions", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: [SubscriptionChannel].self)
  }

  func feed(page: Int, limit: Int) async throws -> SubscriptionsFeedPage {
    let endpoint = APIEndpoint(
      path: "/subscriptions/feed",
      method: .get,
      queryItems: [
        URLQueryItem(name: "page", value: "\(max(0, page))"),
        URLQueryItem(name: "limit", value: "\(max(1, limit))"),
      ],
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: SubscriptionsFeedPage.self)
  }

  func deleteChannel(_ channelURL: String) async throws {
    let endpoint = APIEndpoint(
      path: "/subscriptions/\(encoded(channelURL))",
      method: .delete,
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  private func encoded(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }
}
