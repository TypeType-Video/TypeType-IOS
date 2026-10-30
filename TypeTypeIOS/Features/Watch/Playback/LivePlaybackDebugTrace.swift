import Foundation
import OSLog

enum LivePlaybackDebugTrace {
  #if DEBUG
  private static let origin = ContinuousClock.now
  #endif

  static func measure<T>(_ label: @autoclosure () -> String, _ body: () async throws -> T) async rethrows -> T {
    #if DEBUG
    let start = ContinuousClock.now
    do {
      let value = try await body()
      log(label(), start: start, outcome: "ok")
      return value
    } catch {
      log(label(), start: start, outcome: "error \(error)")
      throw error
    }
    #else
    return try await body()
    #endif
  }

  static func note(_ message: @autoclosure () -> String) {
    #if DEBUG
    let text = message()
    AppLogger.playback.notice("trace note \(text, privacy: .public)")
    #endif
  }

  #if DEBUG
  private static func log(_ label: String, start: ContinuousClock.Instant, outcome: String) {
    let since = Int((start - origin) / .milliseconds(1))
    let took = Int((ContinuousClock.now - start) / .milliseconds(1))
    AppLogger.playback.notice(
      "trace t=\(since) took=\(took)ms \(label, privacy: .public) \(outcome, privacy: .public)"
    )
  }
  #endif
}
