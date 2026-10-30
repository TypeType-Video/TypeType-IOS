import SwiftUI

extension LivePlayerController {
  func showsFullscreenLayout(verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return isPresentingFullscreen }
    return verticalSizeClass == .compact
      && (nativePlayback != nil || isOfflineContent)
  }
}
