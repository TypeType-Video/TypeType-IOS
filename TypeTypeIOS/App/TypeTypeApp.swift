import SwiftUI

@main
struct TypeTypeApp: App {
  var body: some Scene {
    WindowGroup {
      TypeTypeDemoAppView(
        initialAuthMode: UIDemoConfiguration.initialAuthMode,
        launchDestination: UIDemoConfiguration.launchDestination
      )
    }
  }
}
