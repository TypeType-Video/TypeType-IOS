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
      } else if presentsExpandedPlayback {
        // Any minimise or close drops the cover: left up, it shows an empty black page once the video ends.
        presentsExpandedPlayback = false
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

  @ViewBuilder func miniPlayer(
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
      .background(LiveThemeBackground().ignoresSafeArea())
      .presentationDragIndicator(.visible)
    }
  }

  private var offlineDownloads: some View {
    NavigationStack {
      LiveDownloadsView(
        dependencies: coordinator.dependencies,
        center: downloadCenter
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
