import SwiftUI

struct LiveVideoMetadataContentView: View {

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

  var body: some View {
    ScrollViewReader { proxy in
    VStack(spacing: 0) {
      // The player stays pinned: the lower part scrolls under it, the video
      // never leaves the screen (no scroll-away PiP at all).
      LivePlayerView(
        controller: playerController,
        coordinator: playbackCoordinator,
        dependencies: dependencies,
        posterURL: posterURL,
        cinemaMode: $cinemaMode
      )
      .padding(.horizontal, cinemaMode ? -16 : 0)

      ScrollView {
      VStack(alignment: .leading, spacing: 18) {
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

        // The stream arrives with an EMPTY relatedStreams array before the
        // real list loads — an empty list means "still loading" here.
        let relatedReady = !(
          playerController.stream?.relatedStreams.isEmpty ?? true
        )
        if !(playerController.settings.hideRelatedVideos) {
          if relatedReady, let related = playerController.stream?.relatedStreams {
            LiveRelatedVideosSection(
              playerController: playerController,
              videos: related,
              deArrowStore: deArrowStore,
              dependencies: dependencies,
              onSelect: { selectedRelatedVideo = $0 }
            )
          } else {
            // The related section's slot holds a skeleton while the stream
            // loads, so the page shape is stable from the start.
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

        if !playerController.supportsBulletComments {
          if playerController.settings.hideRelatedVideos || relatedReady {
            LiveCommentsSectionView(
              videoURL: resolvedVideo.url,
              dependencies: dependencies,
              onChannel: { selectedChannelURL = $0 },
              onSeekTimestamp: playerController.seek,
              onOpenURL: routeLink
            )
          } else {
            // The page stays put: comments wait in skeleton until the
            // related section exists, so nothing jumps when it arrives.
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
    }
    }
    .toolbar(
      playerController.isPresentingFullscreen ? .hidden : .automatic,
      for: .navigationBar
    )
    .statusBarHidden(playerController.isPresentingFullscreen)
    .animation(.easeInOut(duration: 0.5), value: playerController.isPresentingFullscreen)
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

  private var subscriberCount: Int64? {
    if let count = playerController.stream?.uploaderSubscriberCount,
      count >= 0 {
      return count
    }
    return channelMetadataViewModel.subscriberCount
  }
}
