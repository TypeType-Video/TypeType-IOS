import Foundation

protocol LiveSubscriptionsServiceProtocol {
  func subscriptions() async throws -> [LiveSubscription]
  func feed(
    nextPage: String?,
    filter: LiveSubscriptionFilter
  ) async throws -> LiveSubscriptionFeedPage
  func subscribe(
    channelURL: String,
    name: String,
  avatarURL: String
  ) async throws -> LiveSubscription
  func unsubscribe(channelURL: String) async throws
  func groups() async throws -> [LiveSubscriptionGroup]
  func memberships() async throws -> [LiveSubscriptionGroupMembership]
  func createGroup(name: String) async throws -> LiveSubscriptionGroup
  func renameGroup(id: String, name: String) async throws
  func deleteGroup(id: String) async throws
  func addChannels(_ channelURLs: [String], toGroup id: String) async throws
  func removeChannel(_ channelURL: String, fromGroup id: String) async throws
}

extension LiveSubscriptionsServiceProtocol {
  func feed(
    nextPage: String?,
    filter: LiveSubscriptionFilter
  ) async throws -> LiveSubscriptionFeedPage {
    LiveSubscriptionFeedPage(
      videos: [],
      nextPage: nil,
      generation: nil,
      generatedAt: nil,
      refreshing: false
    )
  }

  func groups() async throws -> [LiveSubscriptionGroup] { [] }

  func memberships() async throws -> [
    LiveSubscriptionGroupMembership
  ] { [] }

  func createGroup(name: String) async throws -> LiveSubscriptionGroup {
    LiveSubscriptionGroup(
      id: UUID().uuidString,
      name: name,
      channelCount: 0,
      createdAt: 0,
      updatedAt: 0
    )
  }

  func renameGroup(id: String, name: String) async throws {}
  func deleteGroup(id: String) async throws {}

  func addChannels(
    _ channelURLs: [String],
    toGroup id: String
  ) async throws {}

  func removeChannel(
    _ channelURL: String,
    fromGroup id: String
  ) async throws {}
}

final class LiveSubscriptionsService:
  LiveSubscriptionsServiceProtocol {
  let apiClient: APIClient
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
    nextPage: String? = nil,
    filter: LiveSubscriptionFilter = .all
  ) async throws -> LiveSubscriptionFeedPage {
    if filter == .shorts { return try await shorts(page: nextPage) }
    var queryItems = [
      URLQueryItem(name: "limit", value: "30"),
    ]
    if let nextPage, !nextPage.isEmpty {
      queryItems.append(
        URLQueryItem(name: "cursor", value: nextPage)
      )
    }
    switch filter {
    case .all, .shorts:
      break
    case .ungrouped:
      queryItems.append(
        URLQueryItem(name: "ungrouped", value: "true")
      )
    case let .group(id, _):
      queryItems.append(
        URLQueryItem(name: "groupId", value: id)
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

  // Pages are numbered here, where the video feed hands out cursors.
  private func shorts(page: String?) async throws -> LiveSubscriptionFeedPage {
    let endpoint = APIEndpoint(
      path: "/subscriptions/shorts",
      method: .get,
      queryItems: [
        URLQueryItem(name: "page", value: page.flatMap(Int.init).map(String.init) ?? "0"),
        URLQueryItem(name: "limit", value: "30"),
        URLQueryItem(name: "blended", value: "true"),
      ],
      requiresAuth: true,
      timeoutInterval: 90
    )
    return try await apiClient.request(endpoint, as: LiveSubscriptionFeedPage.self)
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
      guard case .statusCode(404, _, _) = error else { throw error }
    }
  }
}
