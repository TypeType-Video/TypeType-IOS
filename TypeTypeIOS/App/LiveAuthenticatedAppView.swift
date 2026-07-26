import SwiftUI

struct LiveAuthenticatedAppView: View {
  enum Tab: Hashable {
    case home
    case subscriptions
    case history
    case playlists
    case more
  }

  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject private var serviceSelection: LiveServiceSelection
  @ObservedObject private var notificationCenter: LiveNotificationCenter
  @State private var selectedTab = Tab.home
  @State private var startupCollection: LiveLibraryCollectionKind?
  @State private var didApplyDefaultLandingPage = false
  @Environment(\.scenePhase) private var scenePhase

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    serviceSelection = coordinator.dependencies.serviceSelection
    notificationCenter = coordinator.dependencies.notificationCenter
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      LiveHomeView(coordinator: coordinator)
        .tabItem {
          Label("Home", systemImage: "house")
        }
        .tag(Tab.home)

      LiveSubscriptionsView(coordinator: coordinator)
      .tabItem {
        Label("Subscriptions", systemImage: "bell")
      }
      .tag(Tab.subscriptions)

      LiveHistoryView(coordinator: coordinator)
      .tabItem {
        Label("History", systemImage: "clock")
      }
      .tag(Tab.history)

      LivePlaylistsView(
        coordinator: coordinator,
        requestedCollection: $startupCollection
      )
      .tabItem {
        Label("Playlists", systemImage: "rectangle.stack.badge.play")
      }
      .tag(Tab.playlists)

      LiveAccountView(coordinator: coordinator)
        .tabItem {
          Label("More", systemImage: "line.3.horizontal")
        }
        .badge(notificationCenter.unreadCount)
        .tag(Tab.more)
    }
    .task {
      await notificationCenter.refresh()
      await applyDefaultLandingPage()
    }
    .task {
      while !Task.isCancelled {
        try? await coordinator.dependencies.sessionActivityService
          .report()
        do {
          try await Task.sleep(for: .seconds(60))
        } catch {
          return
        }
      }
    }
    .onChange(of: scenePhase) {
      guard scenePhase == .active else { return }
      Task {
        try? await coordinator.dependencies.sessionActivityService
          .report()
      }
    }
    .tint(DemoTheme.accent)
    .alert(
      "Video service",
      isPresented: Binding(
        get: { serviceSelection.errorMessage != nil },
        set: {
          if !$0 {
            serviceSelection.dismissError()
          }
        }
      )
    ) {
      Button("OK") {
        serviceSelection.dismissError()
      }
    } message: {
      Text(
        serviceSelection.errorMessage
          ?? "The default service could not be updated."
      )
    }
    .accessibilityIdentifier("live.authenticated.shell")
  }

  @MainActor
  private func applyDefaultLandingPage() async {
    guard !didApplyDefaultLandingPage else { return }
    didApplyDefaultLandingPage = true
    guard let settings = try? await coordinator.dependencies
      .settingsService.settings()
    else {
      return
    }
    switch settings.defaultLandingPage {
    case "subscriptions":
      selectedTab = .subscriptions
    case "history":
      selectedTab = .history
    case "playlists":
      selectedTab = .playlists
    case "watch-later":
      startupCollection = .watchLater
      selectedTab = .playlists
    case "favorites":
      startupCollection = .favorites
      selectedTab = .playlists
    default:
      selectedTab = .home
    }
  }
}
