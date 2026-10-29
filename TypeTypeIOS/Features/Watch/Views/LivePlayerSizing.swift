import SwiftUI

/// A 16:9 card inline; full screen it fills the window and rides the rotation, and its layout priority
/// collapses the metadata below.
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
        // Outermost: a priority buried inside another modifier never
        // reaches the parent VStack, and the metadata then splits the
        // height with the player instead of collapsing.
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

  /// Lower corners round only while the page is scrolled: the "content
  /// slides under the pinned player" hint.
  private var lowerRadius: CGFloat {
    guard isScrolled else { return cinemaMode ? 0 : 16 }
    return 24
  }
}
