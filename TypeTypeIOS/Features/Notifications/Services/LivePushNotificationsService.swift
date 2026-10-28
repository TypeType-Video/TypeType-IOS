import Foundation

protocol LivePushNotificationsServiceProtocol {
  func channelPreferences() async throws -> [
    LiveChannelNotificationPreference
  ]
  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference
  /// Bulk toggle behind "Enable all"/"Disable all": one request with the
  /// channels to flip (TypeType-Android: PUT
  /// notifications/channel-preferences/bulk).
  func setChannelPreferences(
    enabled: Bool,
    channelURLs: [String]
  ) async throws -> [LiveChannelNotificationPreference]
}

extension LivePushNotificationsServiceProtocol {
  /// Per-channel fallback for stubs and tests; the real service replaces
  /// it with the single bulk request.
  func setChannelPreferences(
    enabled: Bool,
    channelURLs: [String]
  ) async throws -> [LiveChannelNotificationPreference] {
    var applied: [LiveChannelNotificationPreference] = []
    for channelURL in channelURLs {
      applied.append(
        try await setChannelPreference(channelURL: channelURL, enabled: enabled)
      )
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
    await LiveNotificationRequestGate.shared.acquire()
    return try await apiClient.request(
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
    await LiveNotificationRequestGate.shared.acquire()
    return try await apiClient.request(
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

  func setChannelPreferences(
    enabled: Bool,
    channelURLs: [String]
  ) async throws -> [LiveChannelNotificationPreference] {
    await LiveNotificationRequestGate.shared.acquire()
    return try await apiClient.request(
      APIEndpoint(
        path: "/notifications/channel-preferences/bulk",
        method: .put,
        body: try APIEndpoint.jsonBody(
          LiveChannelNotificationPreferencesBulkPayload(
            enabled: enabled,
            channelURLs: channelURLs
          )
        ),
        requiresAuth: true
      ),
      as: [LiveChannelNotificationPreference].self
    )
  }
}

/// Mirrors TypeType-Android's `ChannelNotificationPreferencesBulkRequestDto`.
private struct LiveChannelNotificationPreferencesBulkPayload: Encodable {
  let enabled: Bool
  let channelURLs: [String]

  enum CodingKeys: String, CodingKey {
    case enabled
    case channelURLs = "channelUrls"
  }
}

/// Ceiling on outgoing notifications requests per second — the backend
/// allows 120/s, this holds the client at ~60/s.
private actor LiveNotificationRequestGate {
  static let shared = LiveNotificationRequestGate()
  private var nextSlot: ContinuousClock.Instant = .now
  private let spacing: Duration = .milliseconds(17)

  /// Waits until this request's slot before the caller performs it.
  func acquire() async {
    let now = ContinuousClock.Instant.now
    let slot = max(nextSlot, now)
    nextSlot = slot.advanced(by: spacing)
    if slot > now {
      try? await Task.sleep(for: slot - now)
    }
  }
}
