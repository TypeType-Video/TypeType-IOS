import SwiftUI

extension LiveVideoMetadataContentView {
  var subscriberCount: Int64? {
    if let count = playerController.stream?.uploaderSubscriberCount, count >= 0 { return count }
    return channelMetadataViewModel.subscriberCount
  }

  func restoreInlinePlayback() {
    // Back from a push the system may have promoted the layer to PiP while the page was covered: hand it back to the
    // stage.
    if playbackCoordinator.presentation == .mini {
      playbackCoordinator.expand()
    }
    let pip = playerController.pictureInPicture
    if pip.isEngaged || pip.isSystemActive {
      AppLogger.playback.info("pip driver: restoring inline after navigation")
      pip.bringInline()
    }
  }

  func leavePage() {
    playerController.flushHistory()
    // A pushed channel or playlist only covers the page: minimizing here starts PiP, which pauses on the way back.
    guard selectedChannelURL == nil, selectedPublicPlaylist == nil else { return }
    let departingVideoURL = video.url
    Task { @MainActor in
      await Task.yield()
      guard playbackCoordinator.currentVideo?.url == departingVideoURL else { return }
      playbackCoordinator.minimize()
    }
  }
}

extension View {
  func watchNavigation(_ page: LiveVideoMetadataContentView) -> some View {
    navigationDestination(item: page.$selectedChannelURL) { channelURL in
      LiveChannelView(channelURL: channelURL, dependencies: page.dependencies)
    }
    .navigationDestination(item: page.$selectedPublicPlaylist) { playlist in
      LivePublicPlaylistView(playlist: playlist, dependencies: page.dependencies)
    }
    .externalLinkAlert(pendingURL: page.$pendingExternalURL)
  }
}
