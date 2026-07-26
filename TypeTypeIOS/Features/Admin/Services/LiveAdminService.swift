import Foundation

protocol LiveAdminServiceProtocol {
  func settings() async throws -> LiveAdminSettings
  func updateSettings(
    _ settings: LiveAdminSettings
  ) async throws -> LiveAdminSettings
  func users(page: Int, limit: Int) async throws -> LiveAdminUsersPage
  func updateRole(id: String, role: String) async throws
  func setSuspended(id: String, suspended: Bool) async throws
  func updateIdentity(id: String, email: String, name: String) async throws
  func createResetToken(id: String) async throws -> String
  func sessions() async throws -> [LiveAdminSession]
}

final class LiveAdminService: LiveAdminServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func settings() async throws -> LiveAdminSettings {
    try await apiClient.request(
      endpoint("/admin/settings", .get),
      as: LiveAdminSettings.self
    )
  }

  func updateSettings(
    _ settings: LiveAdminSettings
  ) async throws -> LiveAdminSettings {
    try await apiClient.request(
      endpoint(
        "/admin/settings",
        .put,
        body: try APIEndpoint.jsonBody(settings)
      ),
      as: LiveAdminSettings.self
    )
  }

  func users(
    page: Int,
    limit: Int
  ) async throws -> LiveAdminUsersPage {
    try await apiClient.request(
      APIEndpoint(
        path: "/admin/users",
        method: .get,
        queryItems: [
          URLQueryItem(name: "page", value: String(page)),
          URLQueryItem(name: "limit", value: String(limit)),
        ],
        requiresAuth: true
      ),
      as: LiveAdminUsersPage.self
    )
  }

  func updateRole(id: String, role: String) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(id)/role",
        .put,
        body: try APIEndpoint.jsonBody(
          LiveAdminRolePayload(role: role)
        )
      )
    )
  }

  func setSuspended(id: String, suspended: Bool) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(id)/suspend",
        suspended ? .post : .delete
      )
    )
  }

  func updateIdentity(
    id: String,
    email: String,
    name: String
  ) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(id)/identity",
        .put,
        body: try APIEndpoint.jsonBody(
          LiveAdminIdentityPayload(email: email, name: name)
        )
      )
    )
  }

  func createResetToken(id: String) async throws -> String {
    let result = try await apiClient.request(
      endpoint("/admin/users/\(id)/reset-token", .post),
      as: LiveAdminResetToken.self
    )
    return result.resetToken
  }

  func sessions() async throws -> [LiveAdminSession] {
    try await apiClient.request(
      endpoint("/admin/sessions", .get),
      as: [LiveAdminSession].self
    )
  }

  private func endpoint(
    _ path: String,
    _ method: HTTPMethod,
    body: Data? = nil
  ) -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: method,
      body: body,
      requiresAuth: true
    )
  }
}
