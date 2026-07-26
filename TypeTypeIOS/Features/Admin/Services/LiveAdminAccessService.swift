import Foundation

protocol LiveAdminAccessServiceProtocol {
  func managedUsers(
    nextPage: String?
  ) async throws -> LiveAdminManagedUsersPage
  func searchUsers(
    query: String
  ) async throws -> [LiveAdminAllowListUser]
  func userAllowList(id: String) async throws -> LiveAdminUserAllowList
  func updateAccessMode(id: String, mode: String) async throws
  func addChannel(
    userID: String,
    item: LiveContentControlItem
  ) async throws
  func removeChannel(userID: String, url: String) async throws
  func globalPlaylists() async throws -> [LiveAllowedPlaylistItem]
  func addGlobalPlaylist(
    _ item: LiveAllowedPlaylistItem
  ) async throws
  func removeGlobalPlaylist(url: String) async throws
  func addPlaylist(
    userID: String,
    item: LiveAllowedPlaylistItem
  ) async throws
  func removePlaylist(userID: String, url: String) async throws
}

final class LiveAdminAccessService:
  LiveAdminAccessServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func managedUsers(
    nextPage: String? = nil
  ) async throws -> LiveAdminManagedUsersPage {
    var queryItems = [
      URLQueryItem(name: "limit", value: "50"),
    ]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "page", value: nextPage)
      )
    }
    return try await apiClient.request(
      APIEndpoint(
        path: "/admin/users/managed-access",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true
      ),
      as: LiveAdminManagedUsersPage.self
    )
  }

  func searchUsers(
    query: String
  ) async throws -> [LiveAdminAllowListUser] {
    try await apiClient.request(
      APIEndpoint(
        path: "/admin/users/search",
        method: .get,
        queryItems: [
          URLQueryItem(name: "q", value: query),
          URLQueryItem(name: "limit", value: "30"),
        ],
        requiresAuth: true
      ),
      as: [LiveAdminAllowListUser].self
    )
  }

  func userAllowList(
    id: String
  ) async throws -> LiveAdminUserAllowList {
    try await apiClient.request(
      endpoint("/admin/users/\(id)/allow-list", .get),
      as: LiveAdminUserAllowList.self
    )
  }

  func updateAccessMode(id: String, mode: String) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(id)/access-mode",
        .put,
        body: try APIEndpoint.jsonBody(
          LiveAdminAccessModePayload(accessMode: mode)
        )
      )
    )
  }

  func addChannel(
    userID: String,
    item: LiveContentControlItem
  ) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(userID)/allowed/channels",
        .post,
        body: try APIEndpoint.jsonBody(item)
      )
    )
  }

  func removeChannel(userID: String, url: String) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(userID)/allowed/channels/\(url)",
        .delete
      )
    )
  }

  func globalPlaylists() async throws -> [LiveAllowedPlaylistItem] {
    try await apiClient.request(
      endpoint("/admin/allowed/playlists", .get),
      as: [LiveAllowedPlaylistItem].self
    )
  }

  func addGlobalPlaylist(
    _ item: LiveAllowedPlaylistItem
  ) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/allowed/playlists",
        .post,
        body: try APIEndpoint.jsonBody(item)
      )
    )
  }

  func removeGlobalPlaylist(url: String) async throws {
    try await apiClient.request(
      endpoint("/admin/allowed/playlists/\(url)", .delete)
    )
  }

  func addPlaylist(
    userID: String,
    item: LiveAllowedPlaylistItem
  ) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(userID)/allowed/playlists",
        .post,
        body: try APIEndpoint.jsonBody(item)
      )
    )
  }

  func removePlaylist(userID: String, url: String) async throws {
    try await apiClient.request(
      endpoint(
        "/admin/users/\(userID)/allowed/playlists/\(url)",
        .delete
      )
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
