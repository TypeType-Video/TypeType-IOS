import Foundation

protocol LiveYouTubeSessionServiceProtocol {
  func status() async throws -> LiveYouTubeSessionStatus
  func startRemoteBrowser(
    returnTo: String?
  ) async throws -> LiveYouTubeRemoteBrowserSession
  func cancelRemoteBrowser(sessionID: String) async throws
  func disconnect() async throws
}

final class LiveYouTubeSessionService:
  LiveYouTubeSessionServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func status() async throws -> LiveYouTubeSessionStatus {
    try await apiClient.request(
      endpoint("/youtube-session/status", .get),
      as: LiveYouTubeSessionStatus.self
    )
  }

  func startRemoteBrowser(
    returnTo: String?
  ) async throws -> LiveYouTubeRemoteBrowserSession {
    try await apiClient.request(
      endpoint(
        "/youtube-session/browser/start",
        .post,
        body: try APIEndpoint.jsonBody(
          LiveYouTubeRemoteStartPayload(returnTo: returnTo)
        )
      ),
      as: LiveYouTubeRemoteBrowserSession.self
    )
  }

  func cancelRemoteBrowser(sessionID: String) async throws {
    try await apiClient.request(
      endpoint(
        "/youtube-session/browser/\(sessionID)",
        .delete
      )
    )
  }

  func disconnect() async throws {
    try await apiClient.request(
      endpoint("/youtube-session", .delete)
    )
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
