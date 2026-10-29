import SwiftUI

extension LiveAuthenticatedAppView {
  var shell: some View {
    tabs
    .onChange(of: playbackCoordinator.presentation) { _, newValue in
      // System PiP restore: bring the expanded player back. The cover must
      // appear WITHOUT its slide — the system animates the PiP window back
      // onto the player surface, and a sliding cover leaves that target
      // frame at the top of the screen first (the "jump, then settle" one).
      if newValue == .expanded {
        if playbackCoordinator.controller?.pictureInPicture.isEngaged == true {
          var transaction = Transaction()
          transaction.disablesAnimations = true
          withTransaction(transaction) {
            presentsExpandedPlayback = true
          }
        } else {
          presentsExpandedPlayback = true
        }
      }
    }
    .fullScreenCover(
      isPresented: $presentsExpandedPlayback,
      onDismiss: {
        if playbackCoordinator.controller?.isPresentingFullscreen == true {
          playbackCoordinator.controller?.exitNativeFullscreen("cover-dismiss")
        }
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
    Group {
      if #available(iOS 18.0, *) {
        modernTabs
      } else {
        legacyTabs
      }
    }
    // The tab bar floats in a glass pill; without a full-bleed page
    // background the area below it shows the window's black — only the
    // More tab covered it because its List fills the safe area.
    .background(DemoThemeBackground().ignoresSafeArea())
    .toolbarBackground(palette.background, for: .tabBar)
    // Layout-aware: the mini player sits above whatever height the tab
    // bar actually has on this device. The old hardcoded 49pt clearance
    // overlapped the bar on modern devices and on the iPhone SE.
    .overlay {
      // PiP-style free-floating card; the view clamps itself above the tab
      // bar so it never collides with navigation or menus.
      GeometryReader { geo in
        // Safe zones at both edges: the tab bar's inset and the status
        // bar / island's inset, each plus one margin of clearance. The card
        // clamp treats both bands as untouchable.
        miniPlayer(
          containerSize: geo.size,
          tabBarBand: geo.safeAreaInsets.bottom + 12,
          topBand: geo.safeAreaInsets.top + 12
        )
      }
    }
  }

  /// iOS 18+: search rides the tab bar as the system search tab, and the
  /// badge shows active downloads on the library tab like beta does.
  @available(iOS 18.0, *)
  private var modernTabs: some View {
    TabView(selection: selectedTab) {
      Tab("Home", systemImage: "house", value: LiveAuthenticatedTab.home) {
        homeTab
      }
      Tab("Subscriptions", systemImage: "play.square.stack", value: LiveAuthenticatedTab.subscriptions) {
        subscriptionsTab
      }
      Tab("Library", systemImage: "rectangle.stack.badge.play", value: LiveAuthenticatedTab.library) {
        libraryTab
      }
      .badge(downloadCenter.activeCount)
      Tab(value: LiveAuthenticatedTab.search, role: .search) {
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
      libraryTab
        .tabItem { Label("Library", systemImage: "rectangle.stack.badge.play") }
        .badge(downloadCenter.activeCount)
        .tag(LiveAuthenticatedTab.library)
      searchTab
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
        .tag(LiveAuthenticatedTab.search)
    }
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
    // In tab mode "closing" search means going back to the feed tab.
    LiveSearchView(coordinator: coordinator) {
      selectedTab.wrappedValue = .home
    }
  }

  @ViewBuilder private func miniPlayer(
    containerSize: CGSize,
    tabBarBand: CGFloat,
    topBand: CGFloat
  ) -> some View {
    // The in-app card is the FALLBACK for a failed or unavailable PiP —
    // while the system PiP window is engaged it would only duplicate it.
    if playbackCoordinator.showsMiniPlayer,
      playbackCoordinator.controller?.pictureInPicture.isEngaged != true {
      LiveMiniPlayerView(
        coordinator: playbackCoordinator,
        onExpand: {
          playbackCoordinator.expand()
          presentsExpandedPlayback = true
        },
        containerSize: containerSize,
        tabBarBand: tabBarBand,
        topBand: topBand
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
      .background(DemoThemeBackground().ignoresSafeArea())
      .presentationDragIndicator(.visible)
    }
  }

  private var offlineDownloads: some View {
    NavigationStack {
      LiveDownloadsView(
        dependencies: coordinator.dependencies,
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

private extension LiveAuthenticatedAppView {
  /// Pull down on the player to minimize into Picture in Picture.
  var minimizePullDown: some Gesture {
    DragGesture(minimumDistance: 30)
      .onEnded { value in
        guard playbackCoordinator.controller?.isPresentingFullscreen != true,
          value.startLocation.y < 320,
          value.translation.height > 120,
          abs(value.translation.height) > abs(value.translation.width),
          // Only from the top of the page: scrolling through the content
          // (even upward) must never minimize the player.
          playbackCoordinator.controller?.isPlayerSurfaceFullyVisible == true
        else {
          return
        }
        playbackCoordinator.minimize()
        presentsExpandedPlayback = false
      }
  }
}


