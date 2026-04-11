import Foundation

protocol AdminServiceProtocol {
  func users(page: Int, limit: Int) async throws -> AdminUsersPage
  func setRole(userID: String, role: AdminRole) async throws
  func setSuspended(userID: String, suspended: Bool) async throws
  func resetToken(userID: String) async throws -> PasswordResetToken
}

final class AdminService: AdminServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func users(page: Int, limit: Int) async throws -> AdminUsersPage {
    let endpoint = APIEndpoint(
      path: "/admin/users",
      method: .get,
      queryItems: [
        URLQueryItem(name: "page", value: "\(page)"),
        URLQueryItem(name: "limit", value: "\(limit)"),
      ],
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: AdminUsersPage.self)
  }

  func setRole(userID: String, role: AdminRole) async throws {
    let id = encoded(userID)
    let endpoint = APIEndpoint(
      path: "/admin/users/\(id)/role",
      method: .put,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(["role": role.rawValue]),
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func setSuspended(userID: String, suspended: Bool) async throws {
    let id = encoded(userID)
    let endpoint = APIEndpoint(
      path: "/admin/users/\(id)/suspend",
      method: suspended ? .post : .delete,
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func resetToken(userID: String) async throws -> PasswordResetToken {
    let id = encoded(userID)
    let endpoint = APIEndpoint(
      path: "/admin/users/\(id)/reset-token",
      method: .post,
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: PasswordResetToken.self)
  }

  private func encoded(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
  }
}
