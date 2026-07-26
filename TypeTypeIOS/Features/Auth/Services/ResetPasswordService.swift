import Foundation

struct ResetPasswordPayload: Encodable {
  let resetToken: String
  let newPassword: String
}

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
      resetToken: token,
      newPassword: newPassword
    )
    try await apiClient.request(
      APIEndpoint(
        path: "/auth/reset-password",
        method: .post,
        body: try APIEndpoint.jsonBody(payload)
      )
    )
  }
}
