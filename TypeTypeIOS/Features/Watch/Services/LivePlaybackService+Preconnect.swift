import Foundation

/// Lets one media preconnect through per window: the instance keeps an idle
/// connection open for about a minute, so more often only adds requests.
actor LiveMediaPreconnector {
  static let window: Duration = .seconds(30)
  private var lastAt: ContinuousClock.Instant?

  func admit() -> Bool {
    let now = ContinuousClock.now
    if let lastAt, now - lastAt < Self.window { return false }
    lastAt = now
    return true
  }
}

extension LivePlaybackService {
  /// Opens the media connection (TCP and TLS) before playback needs it, so
  /// the first segment does not pay the handshake.
  func preconnectMedia() {
    Task(priority: .utility) { [apiClient, preconnector] in
      guard await preconnector.admit() else { return }
      _ = try? await apiClient.requestData(
        APIEndpoint(
          path: "/instance",
          method: .get,
          timeoutInterval: 10,
          retriesTransientFailures: false,
          isMedia: true
        )
      )
    }
  }
}
