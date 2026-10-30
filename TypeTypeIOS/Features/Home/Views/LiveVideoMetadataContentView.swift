import SwiftUI

struct LiveVideoMetadataContentView: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @ObservedObject var deArrowStore: LiveDeArrowStore
  @ObservedObject var playerController: LivePlayerController
  @ObservedObject private var playbackCoordinator: LivePlaybackCoordinator
  @StateObject private var channelMetadataViewModel:
    LiveVideoChannelMetadataViewModel
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @State var selectedChannelURL: String?
  @State var selectedRelatedVideo: LiveVideoItem?
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

        let relatedReady = !(
          playerController.stream?.relatedStreams.isEmpty ?? true
        )
        if !playerController.isOfflineContent,
          !(playerController.settings.hideRelatedVideos) {
          if relatedReady, let related = playerController.stream?.relatedStreams {
            LiveRelatedVideosSection(
              playerController: playerController,
              videos: related,
              deArrowStore: deArrowStore,
              dependencies: dependencies,
              onSelect: { selectedRelatedVideo = $0 }
            )
          } else {
            VStack(alignment: .leading, spacing: 12) {
              TypeTypeSkeleton(cornerRadius: 6)
                .frame(width: 140, height: 14)
              ForEach(0..<2, id: \.self) { _ in
                HStack(alignment: .top, spacing: 10) {
                  TypeTypeSkeleton(cornerRadius: 8)
                    .frame(width: 160, height: 90)
                  VStack(alignment: .leading, spacing: 6) {
                    TypeTypeSkeleton(cornerRadius: 4)
                      .frame(height: 12)
                    TypeTypeSkeleton(cornerRadius: 4)
                      .frame(width: 180, height: 10)
                  }
                }
              }
            }
            .accessibilityLabel("Loading related videos")
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
          } else {
            VStack(alignment: .leading, spacing: 14) {
              ForEach(0..<3, id: \.self) { _ in
                HStack(alignment: .top, spacing: 10) {
                  TypeTypeSkeleton(cornerRadius: 18)
                    .frame(width: 36, height: 36)
                  VStack(alignment: .leading, spacing: 6) {
                    TypeTypeSkeleton(cornerRadius: 4)
                      .frame(width: 120, height: 10)
                    TypeTypeSkeleton(cornerRadius: 4)
                      .frame(height: 10)
                  }
                }
              }
            }
            .accessibilityLabel("Loading comments")
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
    .background(DemoThemeBackground())
      .liveScrolledState { scrolled in
        isScrolled = scrolled
      }
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
    .onAppear {
      if playbackCoordinator.presentation == .mini {
        playbackCoordinator.expand()
      }
      let pip = playerController.pictureInPicture
      if pip.isEngaged || pip.isSystemActive {
        AppLogger.playback.info("pip driver: restoring inline after navigation")
        pip.bringInline()
      }
    }
    .background(DemoThemeBackground().ignoresSafeArea())
    .onDisappear { playerController.flushHistory() }
  }

  private var subscriberCount: Int64? {
    if let count = playerController.stream?.uploaderSubscriberCount,
      count >= 0 {
      return count
    }
    return channelMetadataViewModel.subscriberCount
  }
}

private struct LiveWatchScrollOffsetKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

private extension View {
  @ViewBuilder
  func liveScrolledState(_ onChange: @escaping (Bool) -> Void) -> some View {
    if #available(iOS 18.0, *) {
      self.onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.y > 8
      } action: { _, scrolled in
        onChange(scrolled)
      }
    } else {
      self.onPreferenceChange(LiveWatchScrollOffsetKey.self) { offset in
        onChange(offset < -8)
      }
    }
  }
}
