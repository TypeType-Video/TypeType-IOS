import SwiftUI

struct LivePlayerSizing: ViewModifier {
  let isFullscreen: Bool
  let cinemaMode: Bool
  var isScrolled = false

  @ViewBuilder
  func body(content: Content) -> some View {
    if isFullscreen {
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .layoutPriority(1)
    } else {
      content
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(
          UnevenRoundedRectangle(
            topLeadingRadius: cinemaMode ? 0 : 16,
            bottomLeadingRadius: lowerRadius,
            bottomTrailingRadius: lowerRadius,
            topTrailingRadius: cinemaMode ? 0 : 16,
            style: .continuous
          )
        )
    }
  }

  private var lowerRadius: CGFloat {
    guard isScrolled else { return cinemaMode ? 0 : 16 }
    return 24
  }
}
