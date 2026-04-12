import Foundation

protocol ProfileServiceProtocol {
  func update(publicUsername: String?, bio: String?) async throws
}

final class ProfileService: ProfileServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func update(publicUsername: String?, bio: String?) async throws {
    let payload = ProfileUpdatePayload(
      publicUsername: normalized(publicUsername),
      bio: normalized(bio)
    )
    let endpoint = APIEndpoint(
      path: "/profile",
      method: .put,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(payload),
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  private func normalized(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
