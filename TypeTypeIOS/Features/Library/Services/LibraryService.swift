import Foundation

protocol LibraryServiceProtocol {
  func history(limit: Int, offset: Int) async throws -> [HistoryEntry]
  func playlists() async throws -> [PlaylistSummary]
  func playlist(id: String) async throws -> PlaylistSummary
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
}
