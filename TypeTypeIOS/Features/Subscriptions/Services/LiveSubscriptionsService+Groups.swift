import Foundation

extension LiveSubscriptionsService {
  func groups() async throws -> [LiveSubscriptionGroup] {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/groups",
        method: .get,
        requiresAuth: true
      ),
      as: [LiveSubscriptionGroup].self
    )
  }

  // Read in pages of 100, the most the server serves at once.
  func memberships() async throws -> [LiveSubscriptionGroupMembership] {
    var items: [LiveSubscriptionGroupMembership] = []
    var page = 0
    while true {
      let answer = try await apiClient.request(
        APIEndpoint(
          path: "/subscriptions/group-memberships/page",
          method: .get,
          queryItems: [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: "100")],
          requiresAuth: true
        ),
        as: LiveSubscriptionMembershipPage.self
      )
      items += answer.items
      guard !answer.items.isEmpty, Int64(items.count) < answer.total, page < 1_000 else { return items }
      page += 1
    }
  }

  func memberships(channelURLs: [String]) async throws -> [LiveSubscriptionGroupMembership] {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/group-memberships/lookup",
        method: .post,
        body: try APIEndpoint.jsonBody(LiveSubscriptionGroupChannelsPayload(channelURLs: channelURLs)),
        requiresAuth: true
      ),
      as: [LiveSubscriptionGroupMembership].self
    )
  }

  func createGroup(name: String) async throws -> LiveSubscriptionGroup {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/groups",
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveSubscriptionGroupNamePayload(name: name)
        ),
        requiresAuth: true
      ),
      as: LiveSubscriptionGroup.self
    )
  }

  func renameGroup(id: String, name: String) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/groups/\(id)",
        method: .put,
        body: try APIEndpoint.jsonBody(
          LiveSubscriptionGroupNamePayload(name: name)
        ),
        requiresAuth: true
      )
    )
  }

  func deleteGroup(id: String) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/groups/\(id)",
        method: .delete,
        requiresAuth: true
      )
    )
  }

  func addChannels(
    _ channelURLs: [String],
    toGroup id: String
  ) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/groups/\(id)/channels",
        method: .put,
        body: try APIEndpoint.jsonBody(
          LiveSubscriptionGroupChannelsPayload(channelURLs: channelURLs)
        ),
        requiresAuth: true
      )
    )
  }

  func removeChannel(
    _ channelURL: String,
    fromGroup id: String
  ) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/groups/\(id)/channels",
        method: .delete,
        queryItems: [
          URLQueryItem(name: "url", value: channelURL),
        ],
        requiresAuth: true
      )
    )
  }
}
