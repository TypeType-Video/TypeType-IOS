import SwiftUI

@main
struct TypeTypeApp: App {
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
