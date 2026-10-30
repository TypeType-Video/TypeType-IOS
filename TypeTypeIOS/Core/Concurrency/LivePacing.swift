import Foundation

struct LivePacing: Sendable {
  let scale: Double

  static let realTime = LivePacing(scale: 1)

  func sleep(for base: Duration) async throws {
    try await Task.sleep(for: base * scale)
  }
}
