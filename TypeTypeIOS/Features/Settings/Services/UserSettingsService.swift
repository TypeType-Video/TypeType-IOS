import Foundation

protocol UserSettingsServiceProtocol {
  func get() async throws -> UserSettings
  func update(_ settings: UserSettings) async throws -> UserSettings
}

final class UserSettingsService: UserSettingsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func get() async throws -> UserSettings {
    let endpoint = APIEndpoint(path: "/settings", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: UserSettings.self)
  }

  func update(_ settings: UserSettings) async throws -> UserSettings {
    let endpoint = APIEndpoint(
      path: "/settings",
      method: .put,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(settings),
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: UserSettings.self)
  }
}
