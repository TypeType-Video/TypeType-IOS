import Foundation

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
