import Foundation

protocol LivePushNotificationsServiceProtocol {
  func channelPreferences() async throws -> [
    LiveChannelNotificationPreference
  ]
  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference
}

final class LivePushNotificationsService: LivePushNotificationsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func channelPreferences() async throws -> [
    LiveChannelNotificationPreference
  ] {
    try await apiClient.request(
      APIEndpoint(
        path: "/notifications/channel-preferences",
        method: .get,
        requiresAuth: true
      ),
      as: [LiveChannelNotificationPreference].self
    )
  }

  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference {
    try await apiClient.request(
      APIEndpoint(
        path: "/notifications/channel-preferences",
        method: .put,
        body: try APIEndpoint.jsonBody(
          LiveChannelNotificationPreferencePayload(
            channelURL: channelURL,
            enabled: enabled
          )
        ),
        requiresAuth: true
      ),
      as: LiveChannelNotificationPreference.self
    )
  }
}
