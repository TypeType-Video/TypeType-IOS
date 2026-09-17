import SwiftUI

@main
struct TypeTypeApp: App {
  init() {
    LiveBackgroundRefreshCoordinator.shared.registerIfNeeded()
  }

  var body: some Scene {
    WindowGroup {
      if MockAppConfiguration.isEnabled {
        TypeTypeDemoAppView(
          initialAuthMode: MockAppConfiguration.initialAuthMode,
          launchDestination: MockAppConfiguration.launchDestination
        )
      } else {
        TypeTypeLiveAppView()
      }
    }
  }
}
