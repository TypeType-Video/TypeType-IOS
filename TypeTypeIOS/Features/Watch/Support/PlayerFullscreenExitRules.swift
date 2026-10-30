import CoreGraphics
import Foundation

enum PlayerFullscreenExitRules {
  // Shared with the speed ramp: a touch held this long belongs to 2x, so dragging down after it never exits.
  static let speedRampHold: TimeInterval = 0.35
  static let edgeDeadzone: CGFloat = 48
  static let completionDistance: CGFloat = 64

  static func canBegin(startLocation: CGPoint, size: CGSize, translation: CGSize) -> Bool {
    guard size.width > 0, size.height > 0 else { return false }
    guard startLocation.y >= edgeDeadzone, startLocation.y <= size.height - edgeDeadzone else { return false }
    guard startLocation.x >= size.width * 0.35, startLocation.x <= size.width * 0.65 else { return false }
    return translation.height > abs(translation.width)
  }

  static func completes(translationHeight: CGFloat) -> Bool {
    translationHeight >= completionDistance
  }
}
