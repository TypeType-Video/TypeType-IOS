import Foundation

protocol LiveAllowedChannelsServiceProtocol {
  func allowedChannelURLs() async throws -> Set<String>
  func allowForEveryone(channelURL: String, name: String, avatarURL: String?) async throws
}

struct LiveAllowedChannelsService: LiveAllowedChannelsServiceProtocol {
  let apiClient: APIClient

  private struct Channel: Codable {
    let url: String
    var name: String?
    var thumbnailUrl: String?
    var global: Bool?
  }

  func allowedChannelURLs() async throws -> Set<String> {
    let channels = try await apiClient.request(
      APIEndpoint(path: "/allowed/channels", method: .get, requiresAuth: true),
      as: [Channel].self
    )
    return Set(channels.map(\.url))
  }

  // The server keeps "global" only for admins and moderators, who manage the family list of the instance.
  func allowForEveryone(channelURL: String, name: String, avatarURL: String?) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: "/allowed/channels",
        method: .post,
        body: try APIEndpoint.jsonBody(Channel(url: channelURL, name: name, thumbnailUrl: avatarURL, global: true)),
        requiresAuth: true,
        retriesTransientFailures: false
      )
    )
  }
}
