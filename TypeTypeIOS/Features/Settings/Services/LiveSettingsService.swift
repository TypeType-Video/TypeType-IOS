import Foundation

protocol LiveSettingsServiceProtocol {
  func settings() async throws -> LiveSettings
  func update(_ settings: LiveSettings) async throws -> LiveSettings
}

final class LiveSettingsService: LiveSettingsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func settings() async throws -> LiveSettings {
    try await apiClient.request(
      APIEndpoint(
        path: "/settings",
        method: .get,
        requiresAuth: true
      ),
      as: LiveSettings.self
    )
  }

  func update(_ settings: LiveSettings) async throws -> LiveSettings {
    try await apiClient.request(
      APIEndpoint(
        path: "/settings",
        method: .put,
        body: try APIEndpoint.jsonBody(settings),
        requiresAuth: true
      ),
      as: LiveSettings.self
    )
  }
}
