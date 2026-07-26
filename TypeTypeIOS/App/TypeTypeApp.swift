import SwiftUI

@main
struct TypeTypeApp: App {
  var body: some Scene {
    WindowGroup {
      TypeTypeDemoAppView(
        initialAuthMode: MockAppConfiguration.initialAuthMode,
        launchDestination: MockAppConfiguration.launchDestination
      )
    }
  }
}
