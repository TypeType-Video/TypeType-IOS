import Foundation

protocol LiveChannelServiceProtocol {
  func channel(
    url: String,
    nextPage: String?,
    sort: LiveChannelSort
  ) async throws -> LiveChannelPage
  func playlists(
    url: String,
    nextPage: String?,
    tab: String?
  ) async throws -> LiveChannelPlaylistsPage
  func podcasts(
    url: String,
    nextPage: String?
  ) async throws -> LivePodcastPage
  func podcastEpisodes(
    url: String,
    nextPage: String?
  ) async throws -> LivePodcastEpisodesPage
  func posts(url: String, nextPage: String?) async throws -> LiveCommunityPostsPage
}

extension LiveChannelServiceProtocol {
  func posts(url: String, nextPage: String?) async throws -> LiveCommunityPostsPage {
    throw NetworkError.statusCode(404, nil)
  }
}

final class LiveChannelService: LiveChannelServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func channel(
    url: String,
    nextPage: String? = nil,
    sort: LiveChannelSort = .latest
  ) async throws -> LiveChannelPage {
    try await apiClient.request(
      APIEndpoint(
        path: "/channel/page",
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveChannelPagePayload(
            url: url,
            nextPage: nextPage,
            sort: sort.rawValue
          )
        ),
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LiveChannelPage.self
    )
  }

  func playlists(
    url: String,
    nextPage: String? = nil,
    tab: String? = nil
  ) async throws -> LiveChannelPlaylistsPage {
    var queryItems = [URLQueryItem(name: "url", value: url)]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "nextpage", value: nextPage)
      )
    }
    if let tab {
      queryItems.append(URLQueryItem(name: "tab", value: tab))
    }
    return try await apiClient.request(
      APIEndpoint(
        path: "/channel/playlists",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LiveChannelPlaylistsPage.self
    )
  }

  func posts(url: String, nextPage: String?) async throws -> LiveCommunityPostsPage {
    var queryItems = [URLQueryItem(name: "url", value: url)]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(URLQueryItem(name: "nextpage", value: nextPage))
    }
    return try await apiClient.request(
      APIEndpoint(path: "/channel/posts", method: .get, queryItems: queryItems, requiresAuth: true, timeoutInterval: 90),
      as: LiveCommunityPostsPage.self
    )
  }

  func podcasts(
    url: String,
    nextPage: String? = nil
  ) async throws -> LivePodcastPage {
    var queryItems = [URLQueryItem(name: "url", value: url)]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "nextpage", value: nextPage)
      )
    }
    return try await apiClient.request(
      APIEndpoint(
        path: "/podcasts",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LivePodcastPage.self
    )
  }

  func podcastEpisodes(
    url: String,
    nextPage: String? = nil
  ) async throws -> LivePodcastEpisodesPage {
    var queryItems = [URLQueryItem(name: "url", value: url)]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "nextpage", value: nextPage)
      )
    }
    return try await apiClient.request(
      APIEndpoint(
        path: "/podcasts/episodes",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LivePodcastEpisodesPage.self
    )
  }
}

private struct LiveChannelPagePayload: Encodable {
  let url: String
  let nextPage: String?
  let sort: String

  private enum CodingKeys: String, CodingKey {
    case url
    case nextPage = "nextpage"
    case sort
  }
}
