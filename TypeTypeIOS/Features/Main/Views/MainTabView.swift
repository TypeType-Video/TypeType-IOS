import SwiftUI

struct MainTabView: View {
  @ObservedObject var coordinator: RootCoordinator

  private var isAdmin: Bool {
    coordinator.currentSession?.role == AuthRole.admin.rawValue
  }

  var body: some View {
    TabView {
      HomePlaceholderView(coordinator: coordinator)
        .tabItem {
          Label("Home", systemImage: "house")
        }

      SearchView(coordinator: coordinator)
        .tabItem {
          Label("Search", systemImage: "magnifyingglass")
        }

      SettingsPlaceholderView(coordinator: coordinator)
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }

      if isAdmin {
        AdminUsersView(coordinator: coordinator)
          .tabItem {
            Label("Admin", systemImage: "person.3")
          }
      }
    }
    .transition(.opacity.combined(with: .move(edge: .trailing)))
  }
}
