import SwiftUI

extension LivePlayerController {
  // On iPhone the layout follows the window, not the flag: the page only turns landscape for full screen,
  // so the player grows inside the rotation animation itself instead of jumping before or after it.
  func showsFullscreenLayout(verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return isPresentingFullscreen }
    return verticalSizeClass == .compact
      && (nativePlayback != nil || isOfflineContent)
  }
}
