import SwiftUI

@main
struct TypeTypeApp: App {
  @UIApplicationDelegateAdaptor(TypeTypeAppDelegate.self) private var appDelegate

  init() {
    // The default URLCache is too small for a feed's thumbnails: scrolling would refetch them.
    URLCache.shared = URLCache(
      memoryCapacity: 64 * 1_024 * 1_024,
      diskCapacity: 512 * 1_024 * 1_024
    )
  }

  var body: some Scene {
    WindowGroup {
      if MockAppConfiguration.isEnabled {
        TypeTypeDemoAppView(
          initialAuthMode: MockAppConfiguration.initialAuthMode,
          launchDestination: MockAppConfiguration.launchDestination
        )
      } else {
        TypeTypeLiveAppView(
          orientationLock: appDelegate.orientationLock,
          backgroundRefresh: appDelegate.backgroundRefresh
        )
      }
    }
  }
}
