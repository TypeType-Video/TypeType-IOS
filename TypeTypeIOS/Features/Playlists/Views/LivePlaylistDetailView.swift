import SwiftUI

struct LivePlaylistDetailView: View {
  @Environment(\.dismiss) var dismiss
  let dependencies: AppDependencies
  let onChanged: () -> Void
  @StateObject var viewModel: LivePlaylistDetailViewModel
  @State var selectedVideo: LiveVideoItem?
  @State var selectedChannelURL: String?
  @State var pendingRemoval: LivePlaylistVideo?
  @State var renamesPlaylist = false
  @State var confirmsDeletion = false

  init(
    playlist: LivePlaylist,
    dependencies: AppDependencies,
    onChanged: @escaping () -> Void
  ) {
    self.dependencies = dependencies
    self.onChanged = onChanged
    _viewModel = StateObject(
      wrappedValue: LivePlaylistDetailViewModel(
        id: playlist.id,
        service: dependencies.playlistsService
      )
    )
  }

  var body: some View {
    content
      .navigationTitle(viewModel.playlist?.name ?? "Playlist")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { toolbarContent }
      .onChange(of: selectedVideo) { _, video in
        guard let video else { return }
        selectedVideo = nil
        // Videos open in the canonical PiP-aware player cover;
        // the navigation push slid a second player page in.
        dependencies.playbackCoordinator.open(video)
      }
      .navigationDestination(item: $selectedChannelURL) { channelURL in
        LiveChannelView(
          channelURL: channelURL,
          dependencies: dependencies
        )
      }
      .task { await viewModel.prepare() }
      .sheet(isPresented: $renamesPlaylist) {
        if let playlist = viewModel.playlist {
          LivePlaylistEditorSheet(
            title: "Edit playlist",
            actionTitle: "Save",
            name: playlist.name,
            description: playlist.description
          ) { name, description in
            Task {
              if await viewModel.rename(
                name: name,
                description: description
              ) {
                renamesPlaylist = false
                onChanged()
              }
            }
          }
        }
      }
      .alert("Playlist", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.playlist.detail")
  }
}
