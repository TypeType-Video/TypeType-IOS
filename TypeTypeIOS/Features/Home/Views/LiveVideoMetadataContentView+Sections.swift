import SwiftUI

extension LiveVideoMetadataContentView {
  @ViewBuilder
  var watchSections: some View {
    LivePlaybackQueueView(coordinator: playbackCoordinator)

    if playerController.stream?.isLive == true, LiveChatSupport.supports(videoURL: resolvedVideo.url) {
      LiveChatSectionView(videoURL: resolvedVideo.url, service: dependencies.liveChatService)
        .id(resolvedVideo.url)
    }

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
}
