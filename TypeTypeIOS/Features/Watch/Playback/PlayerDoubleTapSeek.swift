import CoreGraphics
import Foundation

enum PlayerDoubleTapSeekDirection {
  case back
  case forward
}

struct PlayerDoubleTapSeekFeedback: Equatable, Identifiable {
  let direction: PlayerDoubleTapSeekDirection
  let seconds: Int
  let pulse = UUID()

  var id: UUID { pulse }
}

enum PlayerDoubleTapSeek {
  static let seconds = 10

  static func direction(x: CGFloat, width: CGFloat) -> PlayerDoubleTapSeekDirection? {
    guard width.isFinite, width > 0, x.isFinite, x >= 0, x <= width else {
      return nil
    }

    return x < width / 2 ? .back : .forward
  }

  static func target(
    current: TimeInterval,
    duration: TimeInterval,
    direction: PlayerDoubleTapSeekDirection
  ) -> TimeInterval? {
    let increment = TimeInterval(seconds)
    let boundedDuration = max(duration, 0)
    let target = direction == .back
      ? current - increment
      : current + increment

    guard target.isFinite else { return nil }
    guard boundedDuration > 0 else {
      return direction == .back ? max(target, 0) : nil
    }

    return min(max(target, 0), boundedDuration)
  }
}
