import SwiftUI

extension LiveAuthenticatedAppView {
  var shell: some View {
    tabs
    .onChange(of: playbackCoordinator.presentation) { _, newValue in
      // No slide on a PiP restore: the system animates its window onto the player, and a moving cover shifts that
      // target.
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
    // Full-bleed page background: without it the area under the floating tab bar shows the window's black.
    .background(DemoThemeBackground().ignoresSafeArea())
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
    LiveSearchView(coordinator: coordinator) {
      selectedTab.wrappedValue = .home
    }
  }

  @ViewBuilder private func miniPlayer(
    containerSize: CGSize,
    tabBarBand: CGFloat,
    topBand: CGFloat
  ) -> some View {
    // Only while system PiP is not engaged: the card would duplicate its window.
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
  var minimizePullDown: some Gesture {
    DragGesture(minimumDistance: 30)
      .onEnded { value in
        guard playbackCoordinator.controller?.isPresentingFullscreen != true,
          value.startLocation.y < 320,
          value.translation.height > 120,
          abs(value.translation.height) > abs(value.translation.width),
          // Only from the top of the page: scrolling the content must never minimize the player.
          playbackCoordinator.controller?.isPlayerSurfaceFullyVisible == true
        else {
          return
        }
        playbackCoordinator.minimize()
        presentsExpandedPlayback = false
      }
  }
}
