import SwiftUI

struct LiveVideoMetadataContentView: View {

  static let playerAnchorID = "live.player.anchor"
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject var deArrowStore: LiveDeArrowStore
  @ObservedObject var playerController: LivePlayerController
  @ObservedObject private var playbackCoordinator: LivePlaybackCoordinator
  @StateObject private var channelMetadataViewModel:
    LiveVideoChannelMetadataViewModel
  @State var selectedChannelURL: String?
  @State var selectedRelatedVideo: LiveVideoItem?
  @State var selectedPublicPlaylist: LivePlaylistResult?
  @State var pendingExternalURL: URL?
  @AppStorage("typetype.player.cinema-mode")
  private var cinemaMode = true

  init(
    video: LiveVideoItem,
    dependencies: AppDependencies,
    playerController: LivePlayerController
  ) {
    self.video = video
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    self.playerController = playerController
    playbackCoordinator = dependencies.playbackCoordinator
    _channelMetadataViewModel = StateObject(
      wrappedValue: LiveVideoChannelMetadataViewModel(
        service: dependencies.channelService
      )
    )
  }

  @StateObject private var fullscreenControls = LiveNativeControlsState()

  var body: some View {
    ScrollViewReader { proxy in
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        LivePlayerView(
          controller: playerController,
          coordinator: playbackCoordinator,
          dependencies: dependencies,
          posterURL: posterURL,
          cinemaMode: $cinemaMode
        )
        .id(Self.playerAnchorID)
        .padding(.horizontal, cinemaMode ? -16 : 0)

        LiveVideoMetadataHeader(
          video: resolvedVideo,
          title: playerController.stream?.title ?? branding.title,
          description: playbackDescription,
          subscriberCount: subscriberCount,
          onChannel: {
            selectedChannelURL = resolvedVideo.uploaderURL
          },
          onSeekTimestamp: playerController.seek,
          onOpenURL: routeLink
        )

        LiveVideoEngagementView(
          video: resolvedVideo,
          stream: playerController.stream,
          allowsSubscription: hasPersistentAccount,
          service: dependencies.subscriptionsService,
          subscriberCount: subscriberCount,
          onChannel: {
            selectedChannelURL = resolvedVideo.uploaderURL
          }
        )
        .id(engagementIdentity)

        if let playbackDescription, !playbackDescription.isEmpty {
          LiveVideoDescriptionCard(
            video: resolvedVideo,
            text: playbackDescription,
            likeCount: playerController.stream?.likeCount ?? -1,
            onSeekTimestamp: playerController.seek,
            onOpenURL: routeLink
          )
        }

        LiveVideoLibraryActionsView(
          video: resolvedVideo,
          dependencies: dependencies
        )
        .id(libraryActionsIdentity)

        LivePlaybackQueueView(coordinator: playbackCoordinator)

        if !displayedChapters.isEmpty {
          LiveVideoChaptersView(
            chapters: displayedChapters,
            onSeek: playerController.seek
          )
        }

        if !(playerController.settings.hideRelatedVideos),
          let related = playerController.stream?.relatedStreams {
          LiveRelatedVideosSection(
            playerController: playerController,
            videos: related,
            deArrowStore: deArrowStore,
            dependencies: dependencies,
            onSelect: { selectedRelatedVideo = $0 }
          )
        }

        if !playerController.supportsBulletComments {
          LiveCommentsSectionView(
            videoURL: resolvedVideo.url,
            dependencies: dependencies,
            onChannel: { selectedChannelURL = $0 },
            onSeekTimestamp: playerController.seek,
            onOpenURL: routeLink
          )
        }
      }
      .padding(16)
    }
    .background(DemoThemeBackground())
      .liveThemeRepaint()
    .navigationTitle("Video")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(
      item: $selectedChannelURL
    ) { channelURL in
      LiveChannelView(
        channelURL: channelURL,
        dependencies: dependencies
      )
    }
    .navigationDestination(
      item: $selectedRelatedVideo
    ) { relatedVideo in
      LiveVideoMetadataView(
        video: relatedVideo,
        dependencies: dependencies
      )
    }
    .navigationDestination(
      item: $selectedPublicPlaylist
    ) { playlist in
      LivePublicPlaylistView(
        playlist: playlist,
        dependencies: dependencies
      )
    }
    .externalLinkAlert(pendingURL: $pendingExternalURL)
    .accessibilityIdentifier("live.video.metadata")
    // The landscape stage is a sibling of the scroll, not scroll content:
    // the video layer stays in its window and only its frame changes.
    .overlay {
      if playerController.isPresentingFullscreen,
        let playback = playerController.nativePlayback {
        ZStack(alignment: .bottom) {
          Color.black.ignoresSafeArea()
          LiveNativeVideoView(
            playback: playback,
            controller: playerController,
            surface: .fullscreen
          )
          // Same 16:9 container shape as the page player: the video keeps
          // its anchoring while the window rotates instead of jumping to a
          // full-window frame.
          .aspectRatio(16 / 9, contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .onTapGesture { fullscreenControls.tap() }
          LiveNativePlayerControls(
            controller: playerController,
            controls: fullscreenControls,
            isFullscreen: true
          ) {
            playerController.exitNativeFullscreen()
          }
        }
        .transition(.asymmetric(insertion: .opacity, removal: .identity))
        .gesture(
          DragGesture(minimumDistance: 30)
            .onEnded { value in
              // Dragging down returns the player page with the window.
              guard value.translation.height > 120,
                abs(value.translation.width) < value.translation.height
              else { return }
              playerController.exitNativeFullscreen()
            }
        )
      }
    }
    .toolbar(
      playerController.isPresentingFullscreen ? .hidden : .automatic,
      for: .navigationBar
    )
    .statusBarHidden(playerController.isPresentingFullscreen)
    .animation(.easeInOut(duration: 0.5), value: playerController.isPresentingFullscreen)
    // The docked card: the in-house video floating in the corner while the
    // reader is below the player. One window, no system scene, no stall.
    .overlay(alignment: .bottomTrailing) {
      if playerController.isVideoDocked,
        let playback = playerController.nativePlayback {
        LiveDockedVideoCard(
          playback: playback,
          controller: playerController
        ) {
          withAnimation(.snappy(duration: 0.3)) {
            playerController.isVideoDocked = false
          }
          proxy.scrollTo(Self.playerAnchorID, anchor: .top)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 24)
        .transition(.scale(scale: 0.7).combined(with: .opacity))
      }
    }
    .liveStartupProbe(playerController.lastStartupMilliseconds)
    .environment(\.liveWatchExtrasEnabled, playerController.extrasReleased)
    .task(id: "\(libraryActionsIdentity)|\(playerController.extrasReleased)") {
      guard playerController.extrasReleased else { return }
      await deArrowStore.prepare(resolvedVideo)
    }
    .task(id: "\(channelMetadataIdentity)|\(playerController.extrasReleased)") {
      guard playerController.extrasReleased else { return }
      await channelMetadataViewModel.load(
        channelURL: resolvedVideo.uploaderURL,
        streamSubscriberCount:
          playerController.stream?.uploaderSubscriberCount
      )
    }
    .onDisappear { playerController.flushHistory() }
    }
  }

  private var subscriberCount: Int64? {
    if let count = playerController.stream?.uploaderSubscriberCount,
      count >= 0 {
      return count
    }
    return channelMetadataViewModel.subscriberCount
  }
}

/// The docked corner card while the reader scrolls past the player.
private struct LiveDockedVideoCard: View {
  let playback: LiveNativePlayback
  let controller: LivePlayerController
  let onUndock: () -> Void

  var body: some View {
    LiveNativeVideoView(
      playback: playback,
      controller: controller,
      surface: .mini
    )
    .aspectRatio(16 / 9, contentMode: .fit)
    .frame(width: 220)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(DemoTheme.separator, lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    .onTapGesture { onUndock() }
    .accessibilityLabel("Return video to page")
    .accessibilityIdentifier("live.player.dock")
  }
}
