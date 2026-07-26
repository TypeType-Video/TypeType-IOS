import Foundation

protocol LiveCommentsServiceProtocol {
  func comments(
    url: String,
    nextPage: String?
  ) async throws -> LiveCommentsPage
  func replies(
    url: String,
    repliesPage: String
  ) async throws -> LiveCommentsPage
}

final class LiveCommentsService: LiveCommentsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func comments(
    url: String,
    nextPage: String? = nil
  ) async throws -> LiveCommentsPage {
    var queryItems = [URLQueryItem(name: "url", value: url)]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "nextpage", value: nextPage)
      )
    }
    return try await page(
      path: "/comments",
      queryItems: queryItems
    )
  }

  func replies(
    url: String,
    repliesPage: String
  ) async throws -> LiveCommentsPage {
    try await page(
      path: "/comments/replies",
      queryItems: [
        URLQueryItem(name: "url", value: url),
        URLQueryItem(name: "repliesPage", value: repliesPage),
      ]
    )
  }

  private func page(
    path: String,
    queryItems: [URLQueryItem]
  ) async throws -> LiveCommentsPage {
    try await apiClient.request(
      APIEndpoint(
        path: path,
        method: .get,
        queryItems: queryItems,
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LiveCommentsPage.self
    )
  }
}
