import Foundation

protocol LivePlaylistsServiceProtocol {
  func playlists() async throws -> [LivePlaylist]
  func playlist(id: String) async throws -> LivePlaylist
  func create(name: String, description: String) async throws -> LivePlaylist
  func update(id: String, name: String, description: String) async throws
  func delete(id: String) async throws
  func addVideo(id: String, video: LiveVideoItem) async throws -> LivePlaylistVideo
  func removeVideo(id: String, videoURL: String) async throws
  func reorder(id: String, videoURLs: [String]) async throws
  func savedPlaylists() async throws -> [LiveSavedPlaylist]
  func savePublic(url: String) async throws -> LiveSavedPlaylist
  func removeSaved(id: String) async throws
  func publicPlaylist(
    url: String,
    nextPage: String?
  ) async throws -> LivePublicPlaylistPage
}

final class LivePlaylistsService: LivePlaylistsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func playlists() async throws -> [LivePlaylist] {
    try await apiClient.request(
      endpoint("/playlists", .get),
      as: [LivePlaylist].self
    )
  }

  func playlist(id: String) async throws -> LivePlaylist {
    try await apiClient.request(
      endpoint("/playlists/\(id)", .get),
      as: LivePlaylist.self
    )
  }

  func create(
    name: String,
    description: String
  ) async throws -> LivePlaylist {
    try await apiClient.request(
      endpoint(
        "/playlists",
        .post,
        body: try APIEndpoint.jsonBody(
          LivePlaylistPayload(name: name, description: description)
        )
      ),
      as: LivePlaylist.self
    )
  }

  func update(
    id: String,
    name: String,
    description: String
  ) async throws {
    try await apiClient.request(
      endpoint(
        "/playlists/\(id)",
        .put,
        body: try APIEndpoint.jsonBody(
          LivePlaylistPayload(name: name, description: description)
        )
      )
    )
  }

  func delete(id: String) async throws {
    try await apiClient.request(endpoint("/playlists/\(id)", .delete))
  }

  func addVideo(
    id: String,
    video: LiveVideoItem
  ) async throws -> LivePlaylistVideo {
    try await apiClient.request(
      endpoint(
        "/playlists/\(id)/videos",
        .post,
        body: try APIEndpoint.jsonBody(
          LivePlaylistVideoPayload(video: video)
        )
      ),
      as: LivePlaylistVideo.self
    )
  }

  func removeVideo(id: String, videoURL: String) async throws {
    // The video URL must travel as one path segment: unencoded slashes
    // split it into several segments and the DELETE route no longer
    // matches, so entry removal fails with 404.
    let encodedVideoURL = videoURL.addingPercentEncoding(
      withAllowedCharacters: .urlPathAllowed
        .subtracting(CharacterSet(charactersIn: "/"))
    ) ?? videoURL
    try await apiClient.request(
      endpoint(
        "/playlists/\(id)/videos/\(encodedVideoURL)",
        .delete
      )
    )
  }

  func reorder(id: String, videoURLs: [String]) async throws {
    try await apiClient.request(
      endpoint(
        "/playlists/\(id)/reorder",
        .put,
        body: try APIEndpoint.jsonBody(
          LivePlaylistReorderPayload(order: videoURLs)
        )
      )
    )
  }

  func savedPlaylists() async throws -> [LiveSavedPlaylist] {
    try await apiClient.request(
      endpoint("/saved-playlists", .get),
      as: [LiveSavedPlaylist].self
    )
  }

  func savePublic(url: String) async throws -> LiveSavedPlaylist {
    try await apiClient.request(
      endpoint(
        "/saved-playlists",
        .post,
        body: try APIEndpoint.jsonBody(
          LiveSavePlaylistPayload(url: url)
        )
      ),
      as: LiveSavedPlaylist.self
    )
  }

  func removeSaved(id: String) async throws {
    do {
      try await apiClient.request(
        endpoint("/saved-playlists/\(id)", .delete)
      )
    } catch let error as NetworkError {
      guard case .statusCode(404, _) = error else { throw error }
    }
  }

  func publicPlaylist(
    url: String,
    nextPage: String? = nil
  ) async throws -> LivePublicPlaylistPage {
    var queryItems = [URLQueryItem(name: "url", value: url)]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "nextpage", value: nextPage)
      )
    }
    return try await apiClient.request(
      APIEndpoint(
        path: "/playlist",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LivePublicPlaylistPage.self
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
