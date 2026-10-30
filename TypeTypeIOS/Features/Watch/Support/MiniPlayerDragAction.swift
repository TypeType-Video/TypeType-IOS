import CoreGraphics
import Foundation

enum MiniPlayerDragAction: Equatable {
  case expand
  case close
}

enum MiniPlayerDragGesture {
  static let activationDistance: CGFloat = 56

  static func action(
    forTranslationHeight height: CGFloat
  ) -> MiniPlayerDragAction? {
    guard abs(height) >= activationDistance else { return nil }
    return height < 0 ? .expand : .close
  }
}
