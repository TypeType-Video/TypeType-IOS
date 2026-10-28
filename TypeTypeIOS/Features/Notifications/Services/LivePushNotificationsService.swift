import Foundation

protocol LivePushNotificationsServiceProtocol {
  func channelPreferences() async throws -> [
    LiveChannelNotificationPreference
  ]
  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference
  /// Bulk toggle behind "Enable all"/"Disable all": applied in order,
  /// returns the channels that were updated.
  func setChannelPreferences(
    _ updates: [LiveChannelNotificationPreferencePayload]
  ) async throws -> [LiveChannelNotificationPreference]
}

extension LivePushNotificationsServiceProtocol {
  /// Default bulk path: the server only exposes one PUT per channel, so a
  /// batch is a loop. Lives in the protocol so the settings view model can
  /// drive bulk toggles without every stub implementing it.
  func setChannelPreferences(
    _ updates: [LiveChannelNotificationPreferencePayload]
  ) async throws -> [LiveChannelNotificationPreference] {
    var applied: [LiveChannelNotificationPreference] = []
    for update in updates {
      applied.append(
        try await setChannelPreference(
          channelURL: update.channelURL,
          enabled: update.enabled
        )
      )
      // The instance rate-limits: space the per-channel PUTs so a bulk
      // sweep cannot burst into "429 Too Many Requests".
      try? await Task.sleep(for: .milliseconds(200))
    }
    return applied
  }
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
