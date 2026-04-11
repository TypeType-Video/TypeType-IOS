import Foundation

protocol AuthServiceProtocol {
  func login(email: String, password: String) async throws -> AuthSessionResult
  func register(name: String, email: String, password: String) async throws -> AuthSessionResult
  func refresh(using token: String) async throws -> String
}

final class AuthService: AuthServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func login(email: String, password: String) async throws -> AuthSessionResult {
    let payload = LoginPayload(identifier: email, password: password)
    let token = try await requestToken(path: "/auth/login", payload: payload)
    let me = try await fetchMe(token: token)
    return AuthSessionResult(userID: me.id, email: email, role: me.role, token: token)
  }

  func register(name: String, email: String, password: String) async throws -> AuthSessionResult {
    let payload = RegisterPayload(name: name, email: email, password: password)
    let token = try await requestToken(path: "/auth/register", payload: payload)
    let me = try await fetchMe(token: token)
    return AuthSessionResult(userID: me.id, email: email, role: me.role, token: token)
  }

  func refresh(using token: String) async throws -> String {
    let payload = RefreshPayload(token: token)
    return try await requestToken(path: "/auth/refresh", payload: payload)
  }

  private func requestToken<T: Encodable>(path: String, payload: T) async throws -> String {
    let endpoint = APIEndpoint(
      path: path,
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(payload)
    )
    let response = try await apiClient.request(endpoint, as: AuthTokenResponse.self)
    return response.token
  }

  private func fetchMe(token: String) async throws -> AuthMeResponse {
    let endpoint = APIEndpoint(
      path: "/auth/me",
      method: .get,
      headers: ["Authorization": "Bearer \(token)"]
    )
    return try await apiClient.request(endpoint, as: AuthMeResponse.self)
  }
}
