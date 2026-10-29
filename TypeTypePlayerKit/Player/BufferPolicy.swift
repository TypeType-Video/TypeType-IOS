import Foundation

// Same numbers as the web player (TypeType-Player buffer-policy.ts and playback-rate.ts): both talk to the
// same SABR pump, which repositions on every request it has to wait for.
enum BufferPolicy {
  static let maximumRateAwareGoal: TimeInterval = 60

  /// Faster playback eats the buffer faster, so the goal grows with the rate, up to a minute.
  static func goal(_ base: TimeInterval, rate: Float) -> TimeInterval {
    let scaled = base * max(1, Double(rate))
    return min(scaled, max(base, maximumRateAwareGoal))
  }

  /// Refill only once the buffer drops under two thirds of the goal: requests come in batches.
  static func refillThreshold(goal: TimeInterval) -> TimeInterval {
    min(goal, max(5, goal * 2 / 3))
  }
}
