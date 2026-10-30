import SwiftUI

extension LivePlayerController {
  // On iPhone the layout follows the window, not the flag, so the player grows inside the rotation.
  func showsFullscreenLayout(verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return isPresentingFullscreen }
    return verticalSizeClass == .compact
      && (nativePlayback != nil || isOfflineContent)
  }
}
