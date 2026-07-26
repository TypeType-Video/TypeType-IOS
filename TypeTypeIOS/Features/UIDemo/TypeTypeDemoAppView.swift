import SwiftUI

struct TypeTypeDemoAppView: View {
  let initialAuthMode: DemoAuthMode
  let launchDestination: DemoLaunchDestination
  @State private var isAuthenticated: Bool
  @StateObject private var session = DemoSessionStore()

  init(
    initialAuthMode: DemoAuthMode,
    launchDestination: DemoLaunchDestination
  ) {
    self.initialAuthMode = initialAuthMode
    self.launchDestination = launchDestination
    _isAuthenticated = State(initialValue: launchDestination != .auth)
  }

  var body: some View {
    Group {
      if isAuthenticated {
        DemoHomeShellView(
          launchDestination: launchDestination
        ) {
          withAnimation(.easeInOut(duration: 0.25)) {
            isAuthenticated = false
          }
        }
        .transition(.opacity)
      } else {
        DemoAuthView(initialMode: initialAuthMode) {
          withAnimation(.easeInOut(duration: 0.3)) {
            isAuthenticated = true
          }
        }
        .transition(.opacity)
      }
    }
    .environmentObject(session)
  }
}
