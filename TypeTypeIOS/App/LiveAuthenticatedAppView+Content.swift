import SwiftUI

extension LiveAuthenticatedAppView {
  var shell: some View {
    ZStack {
      tabs
      if presentsSearch {
        LiveSearchView(coordinator: coordinator) {
          presentsSearch = false
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.move(edge: .trailing))
        .zIndex(1)
      }
    }
    .overlay(alignment: .bottom) {
      miniPlayer
    }
    .fullScreenCover(isPresented: $presentsExpandedPlayback) {
      expandedPlayback
    }
    .fullScreenCover(item: $incomingMediaLink) { link in
      LiveIncomingMediaLinkView(
        link: link,
        dependencies: coordinator.dependencies
      )
    }
    .fullScreenCover(isPresented: $presentsOfflineDownloads) {
      offlineDownloads
    }
  }

  private var tabs: some View {
    TabView(selection: $selectedTab) {
      LiveHomeView(
        coordinator: coordinator,
        onPresentSearch: { presentsSearch = true }
      )
      .tabItem { Label("Home", systemImage: "house") }
      .tag(LiveAuthenticatedTab.home)

      LiveSubscriptionsView(coordinator: coordinator)
        .tabItem { Label("Subscriptions", systemImage: "bell") }
        .tag(LiveAuthenticatedTab.subscriptions)

      LiveHistoryView(coordinator: coordinator)
        .tabItem { Label("History", systemImage: "clock") }
        .tag(LiveAuthenticatedTab.history)

      LivePlaylistsView(
        coordinator: coordinator,
        requestedCollection: $startupCollection
      )
      .tabItem {
        Label("Playlists", systemImage: "rectangle.stack.badge.play")
      }
      .tag(LiveAuthenticatedTab.playlists)

      LiveAccountView(coordinator: coordinator)
        .tabItem { Label("More", systemImage: "line.3.horizontal") }
        .badge(notificationCenter.unreadCount)
        .tag(LiveAuthenticatedTab.more)
    }
  }

  @ViewBuilder private var miniPlayer: some View {
    if playbackCoordinator.showsMiniPlayer {
      LiveMiniPlayerView(
        coordinator: playbackCoordinator,
        onExpand: {
          playbackCoordinator.expand()
          presentsExpandedPlayback = true
        }
      )
      .padding(.bottom, presentsSearch ? 0 : 49)
      .transition(.move(edge: .bottom).combined(with: .opacity))
      .zIndex(2)
    }
  }

  @ViewBuilder private var expandedPlayback: some View {
    if let video = playbackCoordinator.currentVideo {
      NavigationStack {
        LiveVideoMetadataView(
          video: video,
          dependencies: coordinator.dependencies
        )
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              playbackCoordinator.minimize()
              presentsExpandedPlayback = false
            } label: {
              Image(systemName: "chevron.down")
            }
            .accessibilityLabel("Minimize player")
          }
        }
      }
    }
  }

  private var offlineDownloads: some View {
    NavigationStack {
      LiveDownloadsView(
        center: downloadCenter,
        onlinePlaybackCoordinator: playbackCoordinator
      )
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close", systemImage: "xmark") {
            presentsOfflineDownloads = false
          }
        }
      }
    }
  }
}
