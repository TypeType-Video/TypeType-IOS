import SwiftUI

extension LiveVideoMetadataContentView {
  var twitchWide: Bool {
    horizontalSizeClass == .regular && !playerController.showsFullscreenLayout(verticalSizeClass: verticalSizeClass)
  }

  var twitchChatInset: CGFloat {
    resolvedVideo.twitchLink != nil && twitchWide ? LiveTwitchWatchPage.chatColumnWidth : 0
  }

  var twitchPage: some View {
    LiveTwitchWatchPage(
      controller: playerController,
      video: resolvedVideo,
      dependencies: dependencies,
      signedIn: hasPersistentAccount,
      wide: twitchWide,
      onChannel: {
        if let link = URL(string: resolvedVideo.uploaderURL).flatMap(LiveTwitchLink.target(for:)) ?? resolvedVideo.twitchLink {
          selectedTwitchLink = link
        }
      },
      onRewind: rewindTwitchLive,
      onOpenURL: routeLink
    )
    .background(LiveThemeBackground())
    .navigationTitle("Video")
    .navigationBarTitleDisplayMode(.inline)
    .watchNavigation(self)
  }
}
