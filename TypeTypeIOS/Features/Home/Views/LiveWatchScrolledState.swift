import SwiftUI

struct LiveWatchScrollOffsetKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

extension View {
  // iOS 18 and later read the scroll geometry directly: the preference measurement never fires on iOS 26.
  @ViewBuilder
  func liveScrolledState(_ onChange: @escaping (Bool) -> Void) -> some View {
    if #available(iOS 18.0, *) {
      self.onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.y > 8
      } action: { _, scrolled in
        onChange(scrolled)
      }
    } else {
      self.onPreferenceChange(LiveWatchScrollOffsetKey.self) { offset in
        onChange(offset < -8)
      }
    }
  }
}
