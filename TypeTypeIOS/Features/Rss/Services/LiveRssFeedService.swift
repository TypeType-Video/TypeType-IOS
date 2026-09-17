import Foundation

protocol LiveRssFeedServiceProtocol {
  func feeds() async throws -> [LiveRssFeed]
  func create(
    draft: LiveRssFeedDraft
  ) async throws -> LiveRssFeedSecret
  func update(
    id: String,
    draft: LiveRssFeedDraft
  ) async throws -> LiveRssFeed
  func setEnabled(
    id: String,
    enabled: Bool
  ) async throws -> LiveRssFeed
  func regenerate(id: String) async throws -> LiveRssFeedSecret
  func delete(id: String) async throws
}

final class LiveRssFeedService: LiveRssFeedServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func feeds() async throws -> [LiveRssFeed] {
    try await apiClient.request(endpoint("/rss/feeds", .get))
  }

  func create(
    draft: LiveRssFeedDraft
  ) async throws -> LiveRssFeedSecret {
    try await apiClient.request(
      endpoint("/rss/feeds", .post, body: try APIEndpoint.jsonBody(draft)),
      as: LiveRssFeedSecret.self
    )
  }

  func update(
    id: String,
    draft: LiveRssFeedDraft
  ) async throws -> LiveRssFeed {
    try await apiClient.request(
      endpoint(
        "/rss/feeds/\(id)",
        .put,
        body: try APIEndpoint.jsonBody(draft)
      )
    )
  }

  func setEnabled(
    id: String,
    enabled: Bool
  ) async throws -> LiveRssFeed {
    try await apiClient.request(
      endpoint(
        "/rss/feeds/\(id)/enabled",
        .put,
        body: try APIEndpoint.jsonBody(
          ["enabled": enabled]
        )
      )
    )
  }

  func regenerate(id: String) async throws -> LiveRssFeedSecret {
    try await apiClient.request(
      endpoint("/rss/feeds/\(id)/regenerate", .post),
      as: LiveRssFeedSecret.self
    )
  }

  func delete(id: String) async throws {
    try await apiClient.request(endpoint("/rss/feeds/\(id)", .delete))
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
