import SwiftUI

@main
struct TypeTypeApp: App {
  @StateObject private var coordinator = RootCoordinator(dependencies: .live)

  var body: some Scene {
    WindowGroup {
      RootView(coordinator: coordinator)
    }
  }
}
