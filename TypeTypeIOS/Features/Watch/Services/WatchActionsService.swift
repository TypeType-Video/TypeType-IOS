import Foundation

private struct FavoriteEntry: Decodable {
  let videoUrl: String
}

private struct WatchLaterEntry: Decodable {
  let url: String
}

private struct SubscriptionEntry: Decodable {
  let channelUrl: String
}

struct WatchLaterCreatePayload: Encodable {
  let url: String
  let title: String
  let thumbnail: String
  let duration: Int64
}

struct SubscriptionCreatePayload: Encodable {
  let channelUrl: String
  let name: String
  let avatarUrl: String
}

protocol WatchActionsServiceProtocol {
  func state(videoURL: String, channelURL: String?) async throws -> WatchActionState
  func setFavorite(videoURL: String, enabled: Bool) async throws
  func setWatchLater(_ payload: WatchLaterCreatePayload, enabled: Bool) async throws
  func setSubscription(_ payload: SubscriptionCreatePayload, enabled: Bool) async throws
}

final class WatchActionsService: WatchActionsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func state(videoURL: String, channelURL: String?) async throws -> WatchActionState {
    let favorites = try await apiClient.request(
      APIEndpoint(path: "/favorites", method: .get, requiresAuth: true),
      as: [FavoriteEntry].self
    )
    let watchLater = try await apiClient.request(
      APIEndpoint(path: "/watch-later", method: .get, requiresAuth: true),
      as: [WatchLaterEntry].self
    )
    let subscriptions = try await apiClient.request(
      APIEndpoint(path: "/subscriptions", method: .get, requiresAuth: true),
      as: [SubscriptionEntry].self
    )

    let favorite = favorites.contains(where: { $0.videoUrl == videoURL })
    let later = watchLater.contains(where: { $0.url == videoURL })
    let subscribed = channelURL.map { channel in
      subscriptions.contains(where: { $0.channelUrl == channel })
    } ?? false

    return WatchActionState(isFavorite: favorite, isWatchLater: later, isSubscribed: subscribed)
  }

  func setFavorite(videoURL: String, enabled: Bool) async throws {
    let endpoint = APIEndpoint(
      path: "/favorites/\(pathEncoded(videoURL))",
      method: enabled ? .post : .delete,
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func setWatchLater(_ payload: WatchLaterCreatePayload, enabled: Bool) async throws {
    if enabled {
      let endpoint = APIEndpoint(
        path: "/watch-later",
        method: .post,
        headers: ["Content-Type": "application/json"],
        body: try APIEndpoint.jsonBody(payload),
        requiresAuth: true
      )
      try await apiClient.request(endpoint)
      return
    }

    let endpoint = APIEndpoint(
      path: "/watch-later/\(pathEncoded(payload.url))",
      method: .delete,
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  func setSubscription(_ payload: SubscriptionCreatePayload, enabled: Bool) async throws {
    if enabled {
      let endpoint = APIEndpoint(
        path: "/subscriptions",
        method: .post,
        headers: ["Content-Type": "application/json"],
        body: try APIEndpoint.jsonBody(payload),
        requiresAuth: true
      )
      try await apiClient.request(endpoint)
      return
    }

    let endpoint = APIEndpoint(
      path: "/subscriptions/\(pathEncoded(payload.channelUrl))",
      method: .delete,
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  private func pathEncoded(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }
}
