import Foundation

protocol LiveHistoryServiceProtocol {
  func history(
    query: String?,
    from: Int64?,
    to: Int64?,
    limit: Int,
    offset: Int
  ) async throws -> [LiveHistoryItem]
  func add(
    video: LiveVideoItem,
    progress: Int64
  ) async throws -> LiveHistoryItem
  func progress(videoURL: String) async throws -> Int64?
  func updateProgress(
    videoURL: String,
    positionMS: Int64
  ) async throws
  func remove(id: String) async throws
  func clear() async throws
}

extension LiveHistoryServiceProtocol {
  func progress(videoURL: String) async throws -> Int64? {
    nil
  }

  func updateProgress(
    videoURL: String,
    positionMS: Int64
  ) async throws {}
}

final class LiveHistoryService: LiveHistoryServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func history(
    query: String?,
    from: Int64?,
    to: Int64?,
    limit: Int,
    offset: Int
  ) async throws -> [LiveHistoryItem] {
    var queryItems = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let query, !query.isEmpty {
      queryItems.append(URLQueryItem(name: "q", value: query))
    }
    if let from {
      queryItems.append(
        URLQueryItem(name: "from", value: String(from))
      )
    }
    if let to {
      queryItems.append(
        URLQueryItem(name: "to", value: String(to))
      )
    }
    let wrapped = try await apiClient.request(
      APIEndpoint(
        path: "/history",
        method: .get,
        queryItems: queryItems,
        requiresAuth: true
      ),
      as: [LiveHistoryItem?].self
    )
    return wrapped.compactMap { $0 }
  }

  func add(
    video: LiveVideoItem,
    progress: Int64
  ) async throws -> LiveHistoryItem {
    try await apiClient.request(
      APIEndpoint(
        path: "/history",
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveHistoryPayload(video: video, progress: progress)
        ),
        requiresAuth: true
      ),
      as: LiveHistoryItem.self
    )
  }

  func updateProgress(
    videoURL: String,
    positionMS: Int64
  ) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/progress",
        method: .put,
        queryItems: [
          URLQueryItem(name: "url", value: videoURL)
        ],
        body: try APIEndpoint.jsonBody(
          LiveProgressPayload(position: max(positionMS, 0))
        ),
        requiresAuth: true
      )
    )
  }

  func progress(videoURL: String) async throws -> Int64? {
    do {
      let item = try await apiClient.request(
        APIEndpoint(
          path: "/progress",
          method: .get,
          queryItems: [
            URLQueryItem(name: "url", value: videoURL)
          ],
          requiresAuth: true
        ),
        as: LiveProgressItem.self
      )
      return max(item.position, 0)
    } catch let error as NetworkError {
      guard case .statusCode(404, _, _) = error else { throw error }
      return nil
    }
  }

  func remove(id: String) async throws {
    do {
      try await apiClient.request(
        APIEndpoint(
          path: "/history/\(id)",
          method: .delete,
          requiresAuth: true
        )
      )
    } catch let error as NetworkError {
      guard case .statusCode(404, _, _) = error else { throw error }
    }
  }

  func clear() async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/history",
        method: .delete,
        requiresAuth: true
      )
    )
  }
}

private struct LiveProgressPayload: Encodable {
  let position: Int64
}

private struct LiveProgressItem: Decodable {
  let position: Int64
}

private struct LiveHistoryPayload: Encodable {
  let url: String
  let title: String
  let thumbnail: String
  let channelName: String
  let channelURL: String
  let channelAvatar: String
  let duration: Int64
  let progress: Int64
  let watchedAt: Int64

  init(video: LiveVideoItem, progress: Int64) {
    url = video.url
    title = video.title
    thumbnail = video.thumbnailURL
    channelName = video.uploaderName
    channelURL = video.uploaderURL
    channelAvatar = video.uploaderAvatarURL
    duration = video.duration
    self.progress = progress
    watchedAt = 0
  }

  private enum CodingKeys: String, CodingKey {
    case url, title, thumbnail, channelName
    case channelURL = "channelUrl"
    case channelAvatar, duration, progress, watchedAt
  }
}
