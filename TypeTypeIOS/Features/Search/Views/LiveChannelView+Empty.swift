import SwiftUI

extension LiveChannelView {
  var emptyTitle: String {
    switch viewModel.selectedTab {
    case .playlists: "No playlists"
    case .courses: "No courses"
    default: "No videos"
    }
  }

  var emptySystemImage: String {
    viewModel.selectedTab.listsPlaylists
      ? "rectangle.stack"
      : "play.rectangle"
  }

  var emptyDescription: String {
    "This channel has no content in the selected section."
  }
}
