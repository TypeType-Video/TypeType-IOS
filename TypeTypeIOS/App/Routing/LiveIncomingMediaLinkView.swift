import SwiftUI

struct LiveIncomingMediaLinkView: View {
  let link: LiveIncomingMediaLink
  let dependencies: AppDependencies
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      destination
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Close", systemImage: "xmark") {
              dismiss()
            }
          }
        }
    }
    .accessibilityIdentifier("live.incoming-link")
  }

  @ViewBuilder
  private var destination: some View {
    switch link.destination {
    case let .video(video):
      LiveVideoMetadataView(
        video: video,
        dependencies: dependencies
      )
    case let .channel(channelURL):
      LiveChannelView(
        channelURL: channelURL,
        dependencies: dependencies
      )
    case let .playlist(playlist):
      LivePublicPlaylistView(
        playlist: playlist,
        dependencies: dependencies
      )
    }
  }
}
