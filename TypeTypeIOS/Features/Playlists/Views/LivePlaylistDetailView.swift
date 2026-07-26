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
      .navigationDestination(item: $selectedVideo) { video in
        LiveVideoMetadataView(
          video: video,
          dependencies: dependencies
        )
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
      .confirmationDialog(
        "Remove video?",
        isPresented: removalBinding,
        titleVisibility: .visible
      ) {
        Button("Remove", role: .destructive) {
          guard let video = pendingRemoval else { return }
          Task { await viewModel.remove(video) }
          pendingRemoval = nil
        }
      }
      .confirmationDialog(
        "Delete playlist?",
        isPresented: $confirmsDeletion,
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          Task {
            if await viewModel.delete() {
              onChanged()
              dismiss()
            }
          }
        }
      } message: {
        Text("This action cannot be undone.")
      }
      .alert("Playlist", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
      .accessibilityIdentifier("live.playlist.detail")
  }
}
