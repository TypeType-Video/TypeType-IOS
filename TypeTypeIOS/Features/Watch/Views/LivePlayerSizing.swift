import SwiftUI

extension LivePlayerController {
  // On iPhone the layout follows the window, not the flag: the page only turns landscape for full screen,
  // so the player grows inside the rotation animation itself instead of jumping before or after it.
  func showsFullscreenLayout(verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return isPresentingFullscreen }
    return verticalSizeClass == .compact && nativePlayback != nil
  }
}

/// Inline the player is a 16:9 card; full screen it fills the window and
/// rides the system rotation animation instead of fading over it.
struct LivePlayerSizing: ViewModifier {
  let isFullscreen: Bool
  let cinemaMode: Bool

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
          RoundedRectangle(
            cornerRadius: cinemaMode ? 0 : 16,
            style: .continuous
          )
        )
    }
  }
}
