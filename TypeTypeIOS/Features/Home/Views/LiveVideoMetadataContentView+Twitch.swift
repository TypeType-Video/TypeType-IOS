import SwiftUI

extension LiveVideoMetadataContentView {
  var twitchWide: Bool {
    horizontalSizeClass == .regular && !playerController.showsFullscreenLayout(verticalSizeClass: verticalSizeClass)
  }

  var twitchChatInset: CGFloat {
    resolvedVideo.twitchLink != nil && twitchWide ? LiveTwitchWatchPage.chatColumnWidth : 0
  }

  // The channel, as the web names a Twitch page: the stream title already sits under the picture.
  private var twitchTitle: String {
    let name = playerController.stream?.uploaderName ?? ""
    return name.isEmpty ? resolvedVideo.uploaderName : name
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
      onOpenURL: routeLink
    )
    .background(LiveThemeBackground())
    .navigationTitle(twitchTitle)
    .navigationBarTitleDisplayMode(.inline)
    .watchNavigation(self)
  }
}
