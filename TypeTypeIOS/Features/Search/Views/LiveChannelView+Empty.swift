import SwiftUI

extension LiveChannelView {
  var emptyTitle: String {
    viewModel.selectedTab == .playlists
      ? "No playlists"
      : "No videos"
  }

  var emptySystemImage: String {
    viewModel.selectedTab == .playlists
      ? "rectangle.stack"
      : "play.rectangle"
  }

  var emptyDescription: String {
    "This channel has no content in the selected section."
  }
}
