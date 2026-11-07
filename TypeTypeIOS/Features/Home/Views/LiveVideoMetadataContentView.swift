import SwiftUI

struct LiveVideoMetadataContentView: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject var deArrowStore: LiveDeArrowStore
  @ObservedObject var playerController: LivePlayerController
  @ObservedObject var playbackCoordinator: LivePlaybackCoordinator
  @StateObject var channelMetadataViewModel:
    LiveVideoChannelMetadataViewModel
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @State var selectedChannelURL: String?
  @State var selectedPublicPlaylist: LivePlaylistResult?
  @State var pendingExternalURL: URL?
  @AppStorage("typetype.player.cinema-mode")
  private var cinemaMode = true
  @State private var isScrolled = false

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

  // No negative inset: nothing around the player has a margin to cancel.
  private var playerInset: CGFloat {
    showsFullscreenLayout || cinemaMode ? 0 : 16
  }

  private var showsFullscreenLayout: Bool {
    playerController.showsFullscreenLayout(verticalSizeClass: verticalSizeClass)
  }

  var body: some View {
    ScrollViewReader { proxy in
    VStack(spacing: 0) {
      Color.clear
        .aspectRatio(16 / 9, contentMode: .fit)
        .padding(.horizontal, playerInset)

      ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        LiveVideoMetadataHeader(
          video: resolvedVideo,
          title: playerController.stream?.title ?? branding.title,
          description: playbackDescription,
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

        LiveVideoLibraryActionsView(
          video: resolvedVideo,
          dependencies: dependencies
        )
        .id(libraryActionsIdentity)

        LivePlaybackQueueView(coordinator: playbackCoordinator)

        // The stream arrives with an empty relatedStreams before the real list: empty means still loading.
        let relatedReady = !(
          playerController.stream?.relatedStreams.isEmpty ?? true
        )
        if !playerController.isOfflineContent,
          !(playerController.settings.hideRelatedVideos) {
          if relatedReady, let related = playerController.stream?.relatedStreams {
            LiveRelatedVideosSection(
              playerController: playerController,
              videos: related.hidingShorts(playerController.settings.hideShorts),
              autoplayEnabled: playerController.autoplayEnabled,
              deArrowStore: deArrowStore,
              dependencies: dependencies,
              onSelect: { playbackCoordinator.open($0) }
            )
            .equatable()
          } else {
            LiveWatchSectionPlaceholder(kind: .related)
          }
        }

        if !playerController.isOfflineContent,
          !playerController.supportsBulletComments {
          if playerController.settings.hideRelatedVideos || relatedReady {
            LiveCommentsSectionView(
              videoURL: resolvedVideo.url,
              dependencies: dependencies,
              onChannel: { selectedChannelURL = $0 },
              onSeekTimestamp: playerController.seek,
              onOpenURL: routeLink
            )
            .equatable()
          } else {
            LiveWatchSectionPlaceholder(kind: .comments)
          }
        }
      }
      .padding(16)
      .background(
        GeometryReader { proxy in
          Color.clear.preference(
            key: LiveWatchScrollOffsetKey.self,
            value: proxy.frame(in: .named("watchScroll")).minY
          )
        }
      )
    }
    .coordinateSpace(name: "watchScroll")
    .background(LiveThemeBackground())
      .liveScrolledState { scrolled in
        isScrolled = scrolled
      }
    .navigationTitle("Video")
    .navigationBarTitleDisplayMode(.inline)
    .watchNavigation(self)
    }
    }
    .overlay(alignment: .top) {
      LivePlayerView(
        controller: playerController,
        coordinator: playbackCoordinator,
        dependencies: dependencies,
        posterURL: posterURL,
        cinemaMode: $cinemaMode,
        isScrolled: isScrolled
      )
      .padding(.horizontal, playerInset)
    }
    .toolbar(showsFullscreenLayout ? .hidden : .automatic, for: .navigationBar)
    .statusBarHidden(showsFullscreenLayout)
    .persistentSystemOverlays(showsFullscreenLayout ? .hidden : .automatic)
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
    .onAppear(perform: restoreInlinePlayback)
    .background(LiveThemeBackground().ignoresSafeArea())
    .onDisappear(perform: leavePage)
  }
}
