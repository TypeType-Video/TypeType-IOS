import Foundation

struct LiveDownloadRetryPolicy: Equatable, Sendable {
  let maxAttempts: Int
  let delays: [Duration]

  static let standard = LiveDownloadRetryPolicy(
    maxAttempts: 5,
    delays: [
      .milliseconds(1_500),
      .seconds(3),
      .seconds(6),
      .seconds(12),
    ]
  )

  func delayBeforeAttempt(_ attempt: Int) -> Duration? {
    guard (1...maxAttempts).contains(attempt) else { return nil }
    let index = min(attempt - 1, delays.count - 1)
    return delays[index]
  }
}
