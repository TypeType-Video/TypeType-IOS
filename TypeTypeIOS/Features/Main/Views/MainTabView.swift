import SwiftUI

struct MainTabView: View {
  @ObservedObject var coordinator: RootCoordinator

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

      SubscriptionsView(coordinator: coordinator)
        .tabItem {
          Label("Subs", systemImage: "dot.radiowaves.left.and.right")
        }

      NotificationsView(coordinator: coordinator)
        .tabItem {
          Label("Alerts", systemImage: "bell")
        }

      LibraryView(coordinator: coordinator)
        .tabItem {
          Label("Library", systemImage: "books.vertical")
        }

      SettingsView(coordinator: coordinator)
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
    }
    .transition(.opacity.combined(with: .move(edge: .trailing)))
  }
}
