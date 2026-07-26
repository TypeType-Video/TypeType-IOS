import SwiftUI

struct DemoHomeShellView: View {
  enum Tab: Hashable {
    case home
    case subscriptions
    case history
    case playlists
    case more
  }

  let launchDestination: DemoLaunchDestination
  let onSignOut: () -> Void
  @EnvironmentObject private var session: DemoSessionStore
  @State private var selectedTab: Tab
  @State private var expandedVideo: DemoVideo?
  @State private var didApplyLandingPage = false

  init(
    launchDestination: DemoLaunchDestination,
    onSignOut: @escaping () -> Void
  ) {
    self.launchDestination = launchDestination
    self.onSignOut = onSignOut
    _selectedTab = State(initialValue: Self.initialTab(launchDestination))
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      DemoHomeFeedView(
        onSignOut: onSignOut,
        initialVideo: launchDestination == .player
          ? DemoMockCatalog.continueWatching[0]
          : nil,
        initiallyPresentsSearch: launchDestination == .search
      )
        .id(
          "home-\(session.preferences.showsContinueWatching)-"
            + "\(session.preferences.showsRecommendations)"
        )
        .tabItem {
          Label("Home", systemImage: "house")
        }
        .tag(Tab.home)

      DemoSubscriptionsView(
        initialSection:
          launchDestination == .subscriptionChannels ? .channels : .videos
      )
        .tabItem {
          Label("Subscriptions", systemImage: "bell")
        }
        .tag(Tab.subscriptions)

      DemoHistoryView()
        .tabItem {
          Label("History", systemImage: "clock")
        }
        .tag(Tab.history)

      DemoPlaylistsView(initialPlaylistID: landingPlaylistID)
        .tabItem {
          Label("Playlists", systemImage: "rectangle.stack.badge.play")
        }
        .tag(Tab.playlists)

      DemoMoreView(onSignOut: onSignOut)
        .tabItem {
          Label("More", systemImage: "line.3.horizontal")
        }
        .tag(Tab.more)
    }
    .overlay(alignment: .bottom) {
      if session.isMiniPlayerVisible, let video = session.activeVideo {
        DemoMiniPlayerView(
          video: video,
          controller: session.playerController,
          onExpand: { expandedVideo = video },
          onClose: session.closePlayback
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 49)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(2)
      }
    }
    .fullScreenCover(item: $expandedVideo) { video in
      NavigationStack {
        DemoWatchView(video: video)
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button {
                expandedVideo = nil
              } label: {
                Image(systemName: "chevron.down")
              }
              .accessibilityLabel("Minimize player")
            }
          }
      }
    }
    .animation(.snappy, value: session.isMiniPlayerVisible)
    .onAppear(perform: applyLandingPage)
    .tint(session.preferences.accentColor)
    .preferredColorScheme(session.preferences.colorScheme)
  }

  private static func initialTab(_ destination: DemoLaunchDestination) -> Tab {
    switch destination {
    case .subscriptions, .subscriptionChannels:
      return .subscriptions
    case .history:
      return .history
    case .playlists:
      return .playlists
    case .more:
      return .more
    case .search:
      return .home
    default:
      return .home
    }
  }

  private func applyLandingPage() {
    guard !didApplyLandingPage, usesLandingPreference else { return }
    didApplyLandingPage = true
    switch session.preferences.landingPage {
    case "subscriptions":
      selectedTab = .subscriptions
    case "history":
      selectedTab = .history
    case "playlists", "watch-later", "favorites":
      selectedTab = .playlists
    default:
      selectedTab = .home
    }
  }

  private var usesLandingPreference: Bool {
    launchDestination == .auth || launchDestination == .home
  }

  private var landingPlaylistID: String? {
    guard usesLandingPreference else { return nil }
    switch session.preferences.landingPage {
    case "watch-later", "favorites":
      return session.preferences.landingPage
    default:
      return nil
    }
  }
}
