import SwiftUI

extension LiveAuthenticatedAppView {
  var tabs: some View {
    Group {
      if #available(iOS 18.0, *) {
        modernTabs
      } else {
        legacyTabs
      }
    }
    // Full-bleed page background: without it the area under the floating tab bar shows the window's black.
    .background(LiveThemeBackground().ignoresSafeArea())
    .toolbarBackground(palette.background, for: .tabBar)
    .overlay {
      GeometryReader { geo in
        miniPlayer(
          containerSize: geo.size,
          tabBarBand: geo.safeAreaInsets.bottom + 12,
          topBand: geo.safeAreaInsets.top + 12
        )
      }
    }
  }

  @available(iOS 18.0, *)
  private var modernTabs: some View {
    TabView(selection: selectedTab) {
      Tab("Home", systemImage: "house", value: LiveAuthenticatedTab.home) {
        homeTab
      }
      Tab("Subscriptions", systemImage: "play.square.stack", value: LiveAuthenticatedTab.subscriptions) {
        subscriptionsTab
      }
      if let twitchService {
        Tab("Live", systemImage: "dot.radiowaves.left.and.right", value: LiveAuthenticatedTab.twitch) {
          LiveTwitchView(service: twitchService)
            .environment(\.liveTwitchPlay) { playbackCoordinator.open($0) }
            .environment(\.liveTwitchAccount, twitchAccountService)
        }
      }
      Tab("Library", systemImage: "rectangle.stack.badge.play", value: LiveAuthenticatedTab.library) {
        libraryTab
      }
      .badge(downloadCenter.activeCount)
      Tab("Search", systemImage: "magnifyingglass", value: LiveAuthenticatedTab.search) {
        searchTab
      }
    }
  }

  private var legacyTabs: some View {
    TabView(selection: selectedTab) {
      homeTab
        .tabItem { Label("Home", systemImage: "house") }
        .tag(LiveAuthenticatedTab.home)
      subscriptionsTab
        .tabItem { Label("Subscriptions", systemImage: "play.square.stack") }
        .tag(LiveAuthenticatedTab.subscriptions)
      if let twitchService {
        LiveTwitchView(service: twitchService)
          .environment(\.liveTwitchPlay) { playbackCoordinator.open($0) }
          .environment(\.liveTwitchAccount, twitchAccountService)
          .tabItem { Label("Live", systemImage: "dot.radiowaves.left.and.right") }
          .tag(LiveAuthenticatedTab.twitch)
      }
      libraryTab
        .tabItem { Label("Library", systemImage: "rectangle.stack.badge.play") }
        .badge(downloadCenter.activeCount)
        .tag(LiveAuthenticatedTab.library)
      searchTab
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
        .tag(LiveAuthenticatedTab.search)
    }
  }

  private var twitchService: LiveTwitchServiceProtocol? {
    coordinator.dependencies.twitchEnabled ? coordinator.dependencies.twitchService : nil
  }

  private var twitchAccountService: LiveTwitchAccountServiceProtocol? {
    coordinator.currentUser == nil || twitchService == nil ? nil : coordinator.dependencies.twitchAccountService
  }

  private var homeTab: some View {
    LiveHomeView(coordinator: coordinator)
  }

  private var subscriptionsTab: some View {
    LiveSubscriptionsView(coordinator: coordinator)
  }

  private var libraryTab: some View {
    LiveLibraryView(coordinator: coordinator, section: $librarySection)
  }

  private var searchTab: some View {
    LiveSearchView(coordinator: coordinator)
  }
}
