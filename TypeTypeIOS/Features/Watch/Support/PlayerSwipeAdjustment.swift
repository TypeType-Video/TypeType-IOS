import CoreGraphics
import Foundation

enum PlayerSwipeAdjustmentKind: Equatable {
  case brightness
  case volume
}

enum PlayerSwipeAdjustmentEvent {
  case began(
    kind: PlayerSwipeAdjustmentKind,
    fraction: CGFloat
  )
  case updated(
    kind: PlayerSwipeAdjustmentKind,
    fraction: CGFloat
  )
  case ended
}

struct PlayerSwipeAdjustmentState: Equatable, Identifiable {
  let kind: PlayerSwipeAdjustmentKind
  let fraction: CGFloat
  var id: PlayerSwipeAdjustmentKind { kind }

  var percent: Int {
    Int((fraction * 100).rounded())
  }
}

enum PlayerHorizontalSeekEvent: Equatable {
  case began(position: TimeInterval)
  case updated(position: TimeInterval, isFine: Bool)
  case ended(position: TimeInterval)
}

enum PlayerSwipeAdjustmentRules {
  static let verticalBias: CGFloat = 1.5
  static let travelFactor: CGFloat = 0.7

  static func kind(
    startLocation: CGPoint,
    size: CGSize,
    translation: CGSize
  ) -> PlayerSwipeAdjustmentKind? {
    guard size.width > 0, size.height > 0 else { return nil }
    guard startLocation.y > size.height * 0.10,
      startLocation.y < size.height * 0.66
    else { return nil }
    // Direction only: the recognizer begins after about 10 pt, so a distance gate fails every swipe.
    guard abs(translation.height) >= abs(translation.width) * verticalBias
    else { return nil }

    // Outer thirds only: the centre belongs to the swipe-down gestures.
    guard startLocation.x < size.width / 3
      || startLocation.x > size.width * 2 / 3
    else { return nil }
    return startLocation.x < size.width / 2 ? .brightness : .volume
  }

  static func fraction(
    base: CGFloat,
    translationHeight: CGFloat,
    height: CGFloat
  ) -> CGFloat {
    guard height > 0 else { return min(max(base, 0), 1) }
    let delta = translationHeight / (height * travelFactor)
    return min(max(base - delta, 0), 1)
  }
}
