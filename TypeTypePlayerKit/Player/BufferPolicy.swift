import Foundation

enum BufferPolicy {
  static let maximumRateAwareGoal: TimeInterval = 60

  static func goal(_ base: TimeInterval, rate: Float) -> TimeInterval {
    let scaled = base * max(1, Double(rate))
    return min(scaled, max(base, maximumRateAwareGoal))
  }

  static func refillThreshold(goal: TimeInterval) -> TimeInterval {
    min(goal, max(5, goal * 2 / 3))
  }
}
