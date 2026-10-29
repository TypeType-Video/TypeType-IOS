import SwiftUI

@main
struct TypeTypeApp: App {
  @UIApplicationDelegateAdaptor(TypeTypeAppDelegate.self) private var appDelegate

  init() {
    // AsyncImage loads through URLSession.shared; the default cache is too
    // small to keep a feed's thumbnails, so scrolling refetched them.
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
