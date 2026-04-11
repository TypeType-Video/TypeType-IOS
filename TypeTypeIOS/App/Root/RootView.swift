import SwiftUI

struct RootView: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    ZStack {
      switch coordinator.state {
      case .booting:
        ProgressView()
          .controlSize(.large)
      case .serverSetup:
        ServerListView(coordinator: coordinator)
      case .auth:
        AuthGateView(coordinator: coordinator)
      case .main:
        MainTabView(coordinator: coordinator)
      }
    }
    .padding()
    .animation(TypeTypeMotion.quickEase, value: coordinator.state)
    .task(id: coordinator.selectedServer?.id) {
      await coordinator.verifySelectedSession()
    }
  }
}
