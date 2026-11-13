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
  func search(url: String, query: String, cursor: String?) async throws -> LiveCommentSearchPage
  func voiceAudio(url: String) async throws -> Data
}

extension LiveCommentsServiceProtocol {
  func search(url: String, query: String, cursor: String?) async throws -> LiveCommentSearchPage {
    throw NetworkError.statusCode(404, nil)
  }

  func voiceAudio(url: String) async throws -> Data {
    throw NetworkError.statusCode(404, nil)
  }
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

  func search(url: String, query: String, cursor: String?) async throws -> LiveCommentSearchPage {
    var queryItems = [URLQueryItem(name: "url", value: url), URLQueryItem(name: "q", value: query)]
    if let cursor, !cursor.isEmpty {
      queryItems.append(URLQueryItem(name: "cursor", value: cursor))
    }
    return try await apiClient.request(
      APIEndpoint(path: "/comments/search", method: .get, queryItems: queryItems, requiresAuth: true, timeoutInterval: 90),
      as: LiveCommentSearchPage.self
    )
  }

  func voiceAudio(url: String) async throws -> Data {
    try await apiClient.requestData(
      APIEndpoint(
        path: "/comments/voice",
        method: .get,
        queryItems: [URLQueryItem(name: "url", value: url)],
        requiresAuth: true,
        timeoutInterval: 60
      )
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
