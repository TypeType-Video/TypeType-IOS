import Foundation

protocol NotificationsServiceProtocol {
  func unreadCount() async throws -> Int
  func notifications(page: Int, limit: Int) async throws -> NotificationsPage
  func markAllRead() async throws
}

final class NotificationsService: NotificationsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func unreadCount() async throws -> Int {
    let endpoint = APIEndpoint(path: "/notifications/unread-count", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: UnreadCountResponse.self).unreadCount
  }

  func notifications(page: Int, limit: Int) async throws -> NotificationsPage {
    let endpoint = APIEndpoint(
      path: "/notifications",
      method: .get,
      queryItems: [
        URLQueryItem(name: "page", value: "\(max(0, page))"),
        URLQueryItem(name: "limit", value: "\(max(1, limit))"),
      ],
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: NotificationsPage.self)
  }

  func markAllRead() async throws {
    let endpoint = APIEndpoint(path: "/notifications/read-all", method: .post, requiresAuth: true)
    try await apiClient.request(endpoint)
  }
}
