import Foundation

protocol LiveYouTubeSessionServiceProtocol {
  func status() async throws -> LiveYouTubeSessionStatus
  func startBrowser() async throws -> LiveYouTubeBrowserSession
  func cancelBrowser(sessionID: String) async throws
  func disconnect() async throws
}

struct LiveYouTubeSessionService: LiveYouTubeSessionServiceProtocol {
  let apiClient: APIClient

  func status() async throws -> LiveYouTubeSessionStatus {
    try await apiClient.request(
      APIEndpoint(path: "/youtube-session/status", method: .get, requiresAuth: true),
      as: LiveYouTubeSessionStatus.self
    )
  }

  func startBrowser() async throws -> LiveYouTubeBrowserSession {
    try await apiClient.request(
      APIEndpoint(
        path: "/youtube-session/browser/start",
        method: .post,
        body: try APIEndpoint.jsonBody([String: String]()),
        requiresAuth: true
      ),
      as: LiveYouTubeBrowserSession.self
    )
  }

  func cancelBrowser(sessionID: String) async throws {
    try await apiClient.request(
      APIEndpoint(path: "/youtube-session/browser/\(sessionID)", method: .delete, requiresAuth: true)
    )
  }

  func disconnect() async throws {
    try await apiClient.request(
      APIEndpoint(path: "/youtube-session", method: .delete, requiresAuth: true)
    )
  }

  static func socketURL(for value: String, instance: URL) -> URL? {
    guard let instanceHost = instance.host() else { return nil }
    let resolved: URL?
    if value.hasPrefix("wss://") || value.hasPrefix("ws://") {
      resolved = URL(string: value)
    } else if value.hasPrefix("https://") || value.hasPrefix("http://") {
      resolved = URL(string: value.replacingOccurrences(of: "http", with: "ws", options: .anchored))
    } else {
      let relative = URL(string: value, relativeTo: instance)?.absoluteURL
      resolved = relative.flatMap { URL(string: $0.absoluteString.replacingOccurrences(of: "http", with: "ws", options: .anchored)) }
    }
    guard let url = resolved,
      url.host() == instanceHost,
      url.port == instance.port,
      (url.scheme == "wss") == (instance.scheme == "https")
    else { return nil }
    return url
  }
}
