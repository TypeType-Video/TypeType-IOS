import SwiftUI

extension LiveSearchView {
  func submitSearch(_ value: String? = nil) {
    let serverURL = coordinator.dependencies.serverStore.selectedServer()?.baseURL
    guard let destination = LiveSearchLink.destination(for: value ?? viewModel.query, serverURL: serverURL) else {
      Task { await viewModel.submit(value) }
      return
    }
    viewModel.query = ""
    switch destination {
    case let .video(video):
      coordinator.dependencies.playbackCoordinator.open(video)
    case let .channel(channelURL):
      selectedVideoChannelURL = channelURL
    case let .playlist(playlist):
      selectedPlaylist = playlist
    }
  }
}
