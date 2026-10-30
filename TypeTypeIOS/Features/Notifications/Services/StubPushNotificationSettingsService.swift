import Foundation

struct StubPushNotificationSettingsService: LivePushNotificationsServiceProtocol {
  func channelPreferences() async throws -> [LiveChannelNotificationPreference] {
    throw NetworkError.missingServerURL
  }

  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference {
    throw NetworkError.missingServerURL
  }
}
