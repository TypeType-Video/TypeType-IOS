import Foundation

protocol LibraryServiceProtocol {
  func history(limit: Int, offset: Int) async throws -> [HistoryEntry]
  func playlists() async throws -> [PlaylistSummary]
  func playlist(id: String) async throws -> PlaylistSummary
  func createPlaylist(name: String, description: String) async throws -> PlaylistSummary
  func updatePlaylist(id: String, name: String, description: String) async throws
  func deletePlaylist(id: String) async throws
  func addVideo(to playlistID: String, video: PlaylistVideoCreatePayload) async throws -> PlaylistVideoEntry
  func removeVideo(from playlistID: String, videoURL: String) async throws
}

final class LibraryService: LibraryServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func history(limit: Int = 60, offset: Int = 0) async throws -> [HistoryEntry] {
    let endpoint = APIEndpoint(
      path: "/history",
      method: .get,
      queryItems: [
        URLQueryItem(name: "limit", value: "\(limit)"),
        URLQueryItem(name: "offset", value: "\(offset)"),
      ],
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: [HistoryEntry].self)
  }

  func playlists() async throws -> [PlaylistSummary] {
    let endpoint = APIEndpoint(path: "/playlists", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: [PlaylistSummary].self)
  }

  func playlist(id: String) async throws -> PlaylistSummary {
    let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    let endpoint = APIEndpoint(path: "/playlists/\(encodedID)", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: PlaylistSummary.self)
  }

  func createPlaylist(name: String, description: String = "") async throws -> PlaylistSummary {
    let payload = PlaylistUpdatePayload(name: name, description: description)
    let endpoint = APIEndpoint(
      path: "/playlists",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(payload),
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: PlaylistSummary.self)
  }

  func updatePlaylist(id: String, name: String, description: String = "") async throws {
    let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    let payload = PlaylistUpdatePayload(name: name, description: description)
    let endpoint = APIEndpoint(
      path: "/playlists/\(encodedID)",
      method: .put,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(payload),
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func deletePlaylist(id: String) async throws {
    let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    let endpoint = APIEndpoint(path: "/playlists/\(encodedID)", method: .delete, requiresAuth: true)
    try await apiClient.request(endpoint)
  }

  func addVideo(to playlistID: String, video: PlaylistVideoCreatePayload) async throws -> PlaylistVideoEntry {
    let encodedID = playlistID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? playlistID
    let endpoint = APIEndpoint(
      path: "/playlists/\(encodedID)/videos",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(video),
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: PlaylistVideoEntry.self)
  }

  func removeVideo(from playlistID: String, videoURL: String) async throws {
    let encodedID = playlistID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? playlistID
    let encodedVideo = pathEncoded(videoURL)
    let endpoint = APIEndpoint(
      path: "/playlists/\(encodedID)/videos/\(encodedVideo)",
      method: .delete,
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  private func pathEncoded(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }
}
