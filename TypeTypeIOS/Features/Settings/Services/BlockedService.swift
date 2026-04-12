import Foundation

protocol BlockedServiceProtocol {
  func channels() async throws -> [BlockedItem]
  func videos() async throws -> [BlockedItem]
  func addChannel(url: String, name: String?, thumbnailUrl: String?) async throws
  func addVideo(url: String) async throws
  func removeChannel(url: String) async throws
  func removeVideo(url: String) async throws
}

final class BlockedService: BlockedServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func channels() async throws -> [BlockedItem] {
    let endpoint = APIEndpoint(path: "/blocked/channels", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: [BlockedItem].self)
  }

  func videos() async throws -> [BlockedItem] {
    let endpoint = APIEndpoint(path: "/blocked/videos", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: [BlockedItem].self)
  }

  func addChannel(url: String, name: String?, thumbnailUrl: String?) async throws {
    let endpoint = APIEndpoint(
      path: "/blocked/channels",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(BlockedItem(url: url, name: name, thumbnailUrl: thumbnailUrl)),
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func addVideo(url: String) async throws {
    let endpoint = APIEndpoint(
      path: "/blocked/videos",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(BlockedItem(url: url)),
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func removeChannel(url: String) async throws {
    let escaped = url.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? url
    let endpoint = APIEndpoint(path: "/blocked/channels/\(escaped)", method: .delete, requiresAuth: true)
    try await apiClient.request(endpoint)
  }

  func removeVideo(url: String) async throws {
    let escaped = url.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? url
    let endpoint = APIEndpoint(path: "/blocked/videos/\(escaped)", method: .delete, requiresAuth: true)
    try await apiClient.request(endpoint)
  }
}
