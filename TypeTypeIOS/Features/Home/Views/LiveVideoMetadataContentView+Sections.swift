import SwiftUI

extension LiveVideoMetadataContentView {
  @ViewBuilder
  var watchSections: some View {
    LivePlaybackQueueView(coordinator: playbackCoordinator)

    if resolvedVideo.twitchLink != nil {
      LiveTwitchWatchExtras(controller: playerController, onRewind: rewindTwitchLive)
    }

    if playerController.stream?.isLive == true, LiveChatSupport.supports(videoURL: resolvedVideo.url) {
      LiveChatSectionView(videoURL: resolvedVideo.url, service: dependencies.liveChatService)
        .id(resolvedVideo.url)
    }

    // The stream arrives with an empty relatedStreams before the real list: empty means still loading.
    let relatedReady = !(
      playerController.stream?.relatedStreams.isEmpty ?? true
    )
    if !playerController.isOfflineContent,
      !(playerController.settings.hideRelatedVideos),
      resolvedVideo.twitchLink == nil {
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
      !playerController.supportsBulletComments,
      resolvedVideo.twitchLink == nil {
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

  // The recording resumes at the saved position: saving the chosen moment first opens it right there.
  func rewindTwitchLive(_ archive: LiveTwitchArchive, to position: TimeInterval) {
    let link = LiveTwitchLink.video(archive.id)
    playerController.twitchLive.savesRecordingPosition = false
    Task { [dependencies, playbackCoordinator] in
      do {
        try await dependencies.historyService.updateProgress(
          videoURL: LiveTwitchPlayback.url(for: link), positionMS: Int64(position * 1_000)
        )
      } catch {
        AppLogger.network.failure("Saving the Twitch rewind position", error)
      }
      playbackCoordinator.open(LiveTwitchPlayback.item(for: link))
    }
  }
}
