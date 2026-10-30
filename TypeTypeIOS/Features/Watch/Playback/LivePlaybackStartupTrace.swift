import Foundation
import OSLog

struct LivePlaybackStartupTrace {
  private var startedAt: ContinuousClock.Instant?
  private var steps: [(name: String, at: Duration)] = []

  var isRunning: Bool { startedAt != nil }

  mutating func begin() {
    startedAt = .now
    steps = []
  }

  mutating func mark(_ step: String) {
    guard let startedAt else { return }
    steps.append((step, .now - startedAt))
  }

  mutating func finish(source: String) -> Int? {
    guard let startedAt else { return nil }
    let total = Self.milliseconds(.now - startedAt)
    let detail = steps.map { "\($0.name)=\(Self.milliseconds($0.at))" }.joined(separator: " ")
    AppLogger.playback.notice(
      "startup source=\(source, privacy: .public) total=\(total)ms \(detail, privacy: .public)"
    )
    self.startedAt = nil
    return total
  }

  private static func milliseconds(_ duration: Duration) -> Int {
    let parts = duration.components
    return Int(parts.seconds * 1_000 + parts.attoseconds / 1_000_000_000_000_000)
  }
}
