import Foundation

protocol LiveSubscriptionsServiceProtocol {
  func subscriptions() async throws -> [LiveSubscription]
  func feed(nextPage: String?) async throws -> LiveSubscriptionFeedPage
  func subscribe(
    channelURL: String,
    name: String,
    avatarURL: String
  ) async throws -> LiveSubscription
  func unsubscribe(channelURL: String) async throws
}

final class LiveSubscriptionsService:
  LiveSubscriptionsServiceProtocol {
  private let apiClient: APIClient
  private let decoder = JSONDecoder()

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func subscriptions() async throws -> [LiveSubscription] {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions",
        method: .get,
        requiresAuth: true
      ),
      as: [LiveSubscription].self
    )
  }

  func feed(
    nextPage: String? = nil
  ) async throws -> LiveSubscriptionFeedPage {
    var queryItems = [
      URLQueryItem(name: "limit", value: "30"),
    ]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "cursor", value: nextPage)
      )
    }
    let endpoint = APIEndpoint(
      path: "/subscriptions/feed",
      method: .get,
      queryItems: queryItems,
      requiresAuth: true,
      timeoutInterval: 90
    )

    for _ in 0..<20 {
      try Task.checkCancellation()
      let data = try await apiClient.requestData(endpoint)
      if let page = try? decoder.decode(
        LiveSubscriptionFeedPage.self,
        from: data
      ) {
        return page
      }
      guard let preparing = try? decoder.decode(
        LiveSubscriptionFeedPreparing.self,
        from: data
      ), preparing.code == "subscription_feed_preparing"
      else {
        throw NetworkError.decoding
      }
      let delay = min(
        max(preparing.retryAfterMilliseconds, 100),
        5_000
      )
      try await Task.sleep(
        for: .milliseconds(delay)
      )
    }
    throw NetworkError.transport
  }

  func subscribe(
    channelURL: String,
    name: String,
    avatarURL: String
  ) async throws -> LiveSubscription {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions",
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveSubscriptionPayload(
            channelURL: channelURL,
            name: name,
            avatarURL: avatarURL
          )
        ),
        requiresAuth: true
      ),
      as: LiveSubscription.self
    )
  }

  func unsubscribe(channelURL: String) async throws {
    do {
      try await apiClient.request(
        APIEndpoint(
          path: "/subscriptions",
          method: .delete,
          queryItems: [
            URLQueryItem(name: "url", value: channelURL),
          ],
          requiresAuth: true
        )
      )
    } catch let error as NetworkError {
      guard case .statusCode(404, _) = error else { throw error }
    }
  }
}
