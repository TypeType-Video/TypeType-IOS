import Foundation

protocol ResetPasswordServiceProtocol {
  func reset(token: String, newPassword: String) async throws
}

final class ResetPasswordService: ResetPasswordServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func reset(token: String, newPassword: String) async throws {
    let payload = ResetPasswordPayload(
      resetToken: token.trimmingCharacters(in: .whitespacesAndNewlines),
      newPassword: newPassword
    )
    let endpoint = APIEndpoint(
      path: "/auth/reset-password",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(payload)
    )
    try await apiClient.request(endpoint)
  }
}
