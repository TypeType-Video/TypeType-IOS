import Foundation

protocol LiveLibraryServiceProtocol {
  func favorites() async throws -> [LiveFavoriteItem]
  func favorite(videoURL: String) async throws -> LiveFavoriteItem?
  func addFavorite(videoURL: String) async throws -> LiveFavoriteItem
  func removeFavorite(videoURL: String) async throws
  func watchLater() async throws -> [LiveWatchLaterItem]
  func addWatchLater(video: LiveVideoItem) async throws -> LiveWatchLaterItem
  func removeWatchLater(videoURL: String) async throws
}

final class LiveLibraryService: LiveLibraryServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func favorites() async throws -> [LiveFavoriteItem] {
    try await apiClient.request(
      endpoint("/favorites", .get),
      as: [LiveFavoriteItem].self
    )
  }

  func favorite(videoURL: String) async throws -> LiveFavoriteItem? {
    do {
      return try await apiClient.request(
        endpoint("/favorites/\(videoURL)", .get),
        as: LiveFavoriteItem.self
      )
    } catch let error as NetworkError {
      guard case .statusCode(404, _, _) = error else { throw error }
      return nil
    }
  }

  func addFavorite(videoURL: String) async throws -> LiveFavoriteItem {
    try await apiClient.request(
      endpoint("/favorites/\(videoURL)", .post),
      as: LiveFavoriteItem.self
    )
  }

  func removeFavorite(videoURL: String) async throws {
    try await forgivingDelete("/favorites/\(videoURL)")
  }

  func watchLater() async throws -> [LiveWatchLaterItem] {
    try await apiClient.request(
      endpoint("/watch-later", .get),
      as: [LiveWatchLaterItem].self
    )
  }

  func addWatchLater(
    video: LiveVideoItem
  ) async throws -> LiveWatchLaterItem {
    try await apiClient.request(
      APIEndpoint(
        path: "/watch-later",
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveWatchLaterItem(video: video)
        ),
        requiresAuth: true
      ),
      as: LiveWatchLaterItem.self
    )
  }

  func removeWatchLater(videoURL: String) async throws {
    try await forgivingDelete("/watch-later/\(videoURL)")
  }

  private func forgivingDelete(_ path: String) async throws {
    do {
      try await apiClient.request(endpoint(path, .delete))
    } catch let error as NetworkError {
      guard case .statusCode(404, _, _) = error else { throw error }
    }
  }

  private func endpoint(
    _ path: String,
    _ method: HTTPMethod
  ) -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: method,
      requiresAuth: true
    )
  }
}
