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
      #if DEBUG
      if MockAppConfiguration.isEnabled {
        TypeTypeDemoAppView(
          initialAuthMode: MockAppConfiguration.initialAuthMode,
          launchDestination: MockAppConfiguration.launchDestination
        )
      } else {
        liveApp
      }
      #else
      liveApp
      #endif
    }
  }

  private var liveApp: some View {
    TypeTypeLiveAppView(
      orientationLock: appDelegate.orientationLock,
      backgroundRefresh: appDelegate.backgroundRefresh,
      crashReports: appDelegate.crashReports
    )
  }
}
