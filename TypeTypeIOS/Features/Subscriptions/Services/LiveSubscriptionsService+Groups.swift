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

  func memberships() async throws -> [LiveSubscriptionGroupMembership] {
    try await apiClient.request(
      APIEndpoint(
        path: "/subscriptions/group-memberships",
        method: .get,
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
