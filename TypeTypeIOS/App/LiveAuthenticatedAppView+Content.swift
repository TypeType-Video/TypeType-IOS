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
    
    .onChange(of: playbackCoordinator.presentation) { _, newValue in
      // System PiP restore: bring the expanded player back.
      if newValue == .expanded {
        presentsExpandedPlayback = true
      }
    }
    .fullScreenCover(
      isPresented: $presentsExpandedPlayback,
      onDismiss: {
        guard playbackCoordinator.presentation == .expanded else { return }
        playbackCoordinator.minimize()
      }
    ) {
      expandedPlayback
        .simultaneousGesture(minimizePullDown)
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
    // Layout-aware: the mini player sits above whatever height the tab
    // bar actually has on this device. The old hardcoded 49pt clearance
    // overlapped the bar on modern devices and on the iPhone SE.
    .safeAreaInset(edge: .bottom, spacing: 0) {
      // Zero-height probe directly above the tab bar: its bottom edge in
      // global coordinates is exactly the tab bar top.
      GeometryReader { probe in
        Color.clear.preference(
          key: LiveTabBarTopKey.self,
          value: probe.frame(in: .global).maxY
        )
      }
      .frame(height: 0)
    }
    .onPreferenceChange(LiveTabBarTopKey.self) { value in
      tabBarTopY = value
    }
    .overlay {
      // PiP-style free-floating card; the view clamps itself above the tab
      // bar so it never collides with navigation or menus.
      GeometryReader { geo in
        let measuredBand = tabBarTopY.map {
          geo.frame(in: .global).maxY - $0
        } ?? (geo.safeAreaInsets.bottom + 49)
        miniPlayer(
          containerSize: geo.size,
          tabBarBand: max(measuredBand, 0)
        )
      }
    }
  }

  @ViewBuilder private func miniPlayer(
    containerSize: CGSize,
    tabBarBand: CGFloat
  ) -> some View {
    if playbackCoordinator.showsMiniPlayer {
      LiveMiniPlayerView(
        coordinator: playbackCoordinator,
        onExpand: {
          playbackCoordinator.expand()
          presentsExpandedPlayback = true
        },
        containerSize: containerSize,
        tabBarBand: tabBarBand
      )
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
      .presentationDragIndicator(.visible)
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

private struct LiveTabBarTopKey: PreferenceKey {
  static var defaultValue: CGFloat?

  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    value = nextValue() ?? value
  }
}

private extension LiveAuthenticatedAppView {
  /// Pull down on the player to minimize into Picture in Picture.
  var minimizePullDown: some Gesture {
    DragGesture(minimumDistance: 30)
      .onEnded { value in
        guard value.startLocation.y < 320,
          value.translation.height > 120,
          abs(value.translation.height) > abs(value.translation.width)
        else {
          return
        }
        playbackCoordinator.minimize()
        presentsExpandedPlayback = false
      }
  }
}
