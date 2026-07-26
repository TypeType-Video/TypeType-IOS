import Foundation

protocol OIDCServiceProtocol {
  func status() async throws -> OIDCStatus
  func start(
    redirectURI: URL,
    returnTo: String?
  ) async throws -> URL
  func complete(
    authorizationCode: OIDCAuthorizationCode,
    redirectURI: URL
  ) async throws -> OIDCCallbackResponse
}

final class OIDCService: OIDCServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func status() async throws -> OIDCStatus {
    try await apiClient.request(
      APIEndpoint(path: "/auth/oidc/status", method: .get),
      as: OIDCStatus.self
    )
  }

  func start(
    redirectURI: URL,
    returnTo: String?
  ) async throws -> URL {
    var queryItems = [
      URLQueryItem(
        name: "redirectUri",
        value: redirectURI.absoluteString
      ),
    ]
    if let returnTo, returnTo.hasPrefix("/") {
      queryItems.append(
        URLQueryItem(name: "returnTo", value: returnTo)
      )
    }
    let response = try await apiClient.request(
      APIEndpoint(
        path: "/auth/oidc/start",
        method: .get,
        queryItems: queryItems
      ),
      as: OIDCStartResponse.self
    )
    return response.authorizationURL
  }

  func complete(
    authorizationCode: OIDCAuthorizationCode,
    redirectURI: URL
  ) async throws -> OIDCCallbackResponse {
    let payload = OIDCCallbackPayload(
      code: authorizationCode.code,
      state: authorizationCode.state,
      redirectUri: redirectURI.absoluteString
    )
    return try await apiClient.request(
      APIEndpoint(
        path: "/auth/oidc/callback",
        method: .post,
        body: try APIEndpoint.jsonBody(payload)
      ),
      as: OIDCCallbackResponse.self
    )
  }
}
