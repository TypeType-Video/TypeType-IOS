import Foundation

protocol LivePushNotificationsServiceProtocol {
  func channelPreferences() async throws -> [
    LiveChannelNotificationPreference
  ]
  func setChannelPreference(
    channelURL: String,
    enabled: Bool
  ) async throws -> LiveChannelNotificationPreference
  func setChannelPreferences(
    enabled: Bool,
    channelURLs: [String]
  ) async throws -> [LiveChannelNotificationPreference]
}

extension LivePushNotificationsServiceProtocol {
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
  private let pacing: LivePacing
  private let requestGate = LiveNotificationRequestGate()

  init(apiClient: APIClient, pacing: LivePacing = .realTime) {
    self.apiClient = apiClient
    self.pacing = pacing
  }

  func channelPreferences() async throws -> [
    LiveChannelNotificationPreference
  ] {
    await requestGate.acquire()
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
    await requestGate.acquire()
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
    let endpoint = APIEndpoint(
      path: "/notifications/channel-preferences/bulk",
      method: .put,
      body: try APIEndpoint.jsonBody(
        LiveChannelNotificationPreferencesBulkPayload(enabled: enabled, channelURLs: channelURLs)
      ),
      requiresAuth: true
    )
    var attempt = 0
    while true {
      await requestGate.acquire()
      do {
        return try await apiClient.request(endpoint, as: [LiveChannelNotificationPreference].self)
      } catch {
        attempt += 1
        guard attempt < 3, Self.isTransient(error) else { throw error }
        try await pacing.sleep(for: .seconds(attempt))
      }
    }
  }

  private static func isTransient(_ error: Error) -> Bool {
    switch error as? NetworkError {
    case .transport: true
    case let .statusCode(code, _): code == 429 || (500...599).contains(code)
    default: false
    }
  }

}

private struct LiveChannelNotificationPreferencesBulkPayload: Encodable {
  let enabled: Bool
  let channelURLs: [String]

  enum CodingKeys: String, CodingKey {
    case enabled
    case channelURLs = "channelUrls"
  }
}

// The server allows 120 requests per second; stay near 60.
private actor LiveNotificationRequestGate {
  private var nextSlot: ContinuousClock.Instant = .now
  private let spacing: Duration = .milliseconds(17)

  func acquire() async {
    let now = ContinuousClock.Instant.now
    let slot = max(nextSlot, now)
    nextSlot = slot.advanced(by: spacing)
    if slot > now {
      try? await Task.sleep(for: slot - now)
    }
  }
}
