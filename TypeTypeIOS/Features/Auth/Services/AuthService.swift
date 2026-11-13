import Foundation

protocol AuthServiceProtocol {
  func registrationStatus() async throws -> RegisterStatus
  func login(
    identifier: String,
    password: String
  ) async throws -> AuthSessionResult
  func register(
    name: String,
    email: String,
    password: String
  ) async throws -> AuthSessionResult
  func guestLogin() async throws -> AuthSessionResult
  func refresh() async throws -> String
  func restoreSession(
    snapshot: SessionSnapshot,
    accessToken: String
  ) async throws -> AuthSessionResult
  func user(accessToken: String) async throws -> AuthUser
  func logout() async throws
}

final class AuthService: AuthServiceProtocol {
  private let apiClient: APIClient
  private let refreshTokenProvider: () -> String?

  init(apiClient: APIClient, refreshTokenProvider: @escaping () -> String? = { nil }) {
    self.apiClient = apiClient
    self.refreshTokenProvider = refreshTokenProvider
  }

  func registrationStatus() async throws -> RegisterStatus {
    try await apiClient.request(
      APIEndpoint(path: "/auth/register/status", method: .get),
      as: RegisterStatus.self
    )
  }

  func login(
    identifier: String,
    password: String
  ) async throws -> AuthSessionResult {
    let payload = LoginPayload(
      identifier: identifier,
      password: password
    )
    return try await authenticate(
      path: "/auth/login",
      payload: payload,
      accountIdentifier: identifier
    )
  }

  func register(
    name: String,
    email: String,
    password: String
  ) async throws -> AuthSessionResult {
    let payload = RegisterPayload(
      email: email,
      password: password,
      name: name
    )
    return try await authenticate(
      path: "/auth/register",
      payload: payload,
      accountIdentifier: email
    )
  }

  func guestLogin() async throws -> AuthSessionResult {
    let response = try await requestAccessToken(
      path: "/auth/guest",
      payload: EmptyJSONPayload()
    )
    let user = try await user(accessToken: response)
    return AuthSessionResult(
      user: user,
      accountIdentifier: nil,
      accessToken: response
    )
  }

  func refresh() async throws -> String {
    guard let refreshToken = refreshTokenProvider() else {
      return try await requestAccessToken(
        path: "/auth/refresh",
        payload: EmptyJSONPayload()
      )
    }
    // Without cookies the server reads the token from the body; with them a stale stored cookie would win.
    let endpoint = APIEndpoint(
      path: "/auth/refresh",
      method: .post,
      body: try APIEndpoint.jsonBody(RefreshTokenPayload(token: refreshToken)),
      handlesCookies: false
    )
    return try await apiClient.request(endpoint, as: AuthAccessTokenResponse.self).accessToken
  }

  func restoreSession(
    snapshot: SessionSnapshot,
    accessToken: String
  ) async throws -> AuthSessionResult {
    do {
      let currentUser = try await user(accessToken: accessToken)
      return AuthSessionResult(
        user: currentUser,
        accountIdentifier: snapshot.accountIdentifier,
        accessToken: accessToken
      )
    } catch let error as NetworkError {
      guard case .statusCode(401, _, _) = error else { throw error }
      let refreshedToken = try await refresh()
      let currentUser = try await user(accessToken: refreshedToken)
      return AuthSessionResult(
        user: currentUser,
        accountIdentifier: snapshot.accountIdentifier,
        accessToken: refreshedToken
      )
    }
  }

  func user(accessToken: String) async throws -> AuthUser {
    let endpoint = APIEndpoint(
      path: "/auth/me",
      method: .get,
      headers: ["Authorization": "Bearer \(accessToken)"]
    )
    return try await apiClient.request(endpoint, as: AuthUser.self)
  }

  func logout() async throws {
    try await apiClient.request(
      APIEndpoint(path: "/auth/logout", method: .post)
    )
  }

  private func authenticate<Payload: Encodable>(
    path: String,
    payload: Payload,
    accountIdentifier: String?
  ) async throws -> AuthSessionResult {
    let accessToken = try await requestAccessToken(
      path: path,
      payload: payload
    )
    let currentUser = try await user(accessToken: accessToken)
    return AuthSessionResult(
      user: currentUser,
      accountIdentifier: accountIdentifier,
      accessToken: accessToken
    )
  }

  private func requestAccessToken<Payload: Encodable>(
    path: String,
    payload: Payload
  ) async throws -> String {
    let endpoint = APIEndpoint(
      path: path,
      method: .post,
      body: try APIEndpoint.jsonBody(payload)
    )
    let response = try await apiClient.request(
      endpoint,
      as: AuthAccessTokenResponse.self
    )
    return response.accessToken
  }
}

private struct RefreshTokenPayload: Encodable {
  let token: String
}
