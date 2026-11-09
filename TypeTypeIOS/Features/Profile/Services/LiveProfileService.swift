import Foundation

protocol LiveProfileServiceProtocol {
  func updateProfile(
    publicUsername: String?,
    bio: String?
  ) async throws
  func publicProfile(username: String) async throws -> LivePublicProfile
  func accountIdentity() async throws -> LiveAccountIdentity
  func updateIdentity(
    email: String,
    name: String,
    currentPassword: String
  ) async throws
  func setEmojiAvatar(code: String) async throws
  func uploadAvatar(
    data: Data,
    mediaType: String
  ) async throws -> LiveCustomAvatar
  func clearAvatar() async throws
  func uploadSeekbarIcon(data: Data, mediaType: String) async throws
  func clearSeekbarIcon() async throws
}

final class LiveProfileService: LiveProfileServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func updateProfile(
    publicUsername: String?,
    bio: String?
  ) async throws {
    try await apiClient.request(
      endpoint(
        "/profile",
        .put,
        body: try APIEndpoint.jsonBody(
          LiveProfilePayload(
            publicUsername: publicUsername,
            bio: bio
          )
        )
      )
    )
  }

  func publicProfile(
    username: String
  ) async throws -> LivePublicProfile {
    try await apiClient.request(
      endpoint("/profile/public/\(username)", .get),
      as: LivePublicProfile.self
    )
  }

  func accountIdentity() async throws -> LiveAccountIdentity {
    try await apiClient.request(
      endpoint("/profile/account", .get),
      as: LiveAccountIdentity.self
    )
  }

  func updateIdentity(
    email: String,
    name: String,
    currentPassword: String
  ) async throws {
    try await apiClient.request(
      endpoint(
        "/profile/account",
        .put,
        body: try APIEndpoint.jsonBody(
          LiveAccountIdentityPayload(
            email: email,
            name: name,
            currentPassword: currentPassword
          )
        )
      )
    )
  }

  func setEmojiAvatar(code: String) async throws {
    try await apiClient.request(
      endpoint(
        "/profile/avatar/emoji",
        .put,
        body: try APIEndpoint.jsonBody(
          LiveEmojiAvatarPayload(code: code)
        )
      )
    )
  }

  func uploadAvatar(
    data: Data,
    mediaType: String
  ) async throws -> LiveCustomAvatar {
    try await apiClient.request(
      APIEndpoint(
        path: "/profile/avatar/custom",
        method: .put,
        headers: ["Content-Type": mediaType],
        body: data,
        requiresAuth: true
      ),
      as: LiveCustomAvatar.self
    )
  }

  func clearAvatar() async throws {
    try await apiClient.request(
      endpoint("/profile/avatar", .delete)
    )
  }

  func uploadSeekbarIcon(data: Data, mediaType: String) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/profile/seekbar-icon",
        method: .put,
        headers: ["Content-Type": mediaType],
        body: data,
        requiresAuth: true
      )
    )
  }

  func clearSeekbarIcon() async throws {
    try await apiClient.request(endpoint("/profile/seekbar-icon", .delete))
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
