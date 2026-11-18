import Foundation

protocol LiveFocusServiceProtocol {
  func settings() async throws -> LiveFocusSettings
  func save(_ request: LiveFocusRequest) async throws -> LiveFocusSettings
}

struct LiveFocusService: LiveFocusServiceProtocol {
  let apiClient: APIClient

  func settings() async throws -> LiveFocusSettings {
    try await apiClient.request(APIEndpoint(path: "/focus", method: .get, requiresAuth: true), as: LiveFocusSettings.self)
  }

  func save(_ request: LiveFocusRequest) async throws -> LiveFocusSettings {
    let endpoint = APIEndpoint(path: "/focus", method: .put, body: try APIEndpoint.jsonBody(request), requiresAuth: true, retriesTransientFailures: false)
    return try await apiClient.request(endpoint, as: LiveFocusSettings.self)
  }
}
