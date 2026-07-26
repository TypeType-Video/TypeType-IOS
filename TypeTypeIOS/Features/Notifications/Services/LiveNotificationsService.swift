import Foundation

protocol LiveNotificationsServiceProtocol {
  func unreadCount() async throws -> Int
  func notifications(
    page: Int,
    limit: Int
  ) async throws -> LiveNotificationsPage
  func markAllRead() async throws -> LiveNotificationsReadResult
}

final class LiveNotificationsService: LiveNotificationsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func unreadCount() async throws -> Int {
    let response = try await apiClient.request(
      endpoint("/notifications/unread-count", .get),
      as: LiveUnreadNotifications.self
    )
    return response.unreadCount
  }

  func notifications(
    page: Int,
    limit: Int = 20
  ) async throws -> LiveNotificationsPage {
    try await apiClient.request(
      APIEndpoint(
        path: "/notifications",
        method: .get,
        queryItems: [
          URLQueryItem(name: "page", value: String(page)),
          URLQueryItem(name: "limit", value: String(limit)),
        ],
        requiresAuth: true
      ),
      as: LiveNotificationsPage.self
    )
  }

  func markAllRead() async throws -> LiveNotificationsReadResult {
    try await apiClient.request(
      endpoint("/notifications/read-all", .post),
      as: LiveNotificationsReadResult.self
    )
  }

  private func endpoint(
    _ path: String,
    _ method: HTTPMethod
  ) -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: method,
      requiresAuth: true
    )
  }
}
