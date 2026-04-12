import SwiftUI

struct PlaylistDetailView: View {
  let playlistID: String
  let coordinator: RootCoordinator
  let libraryService: LibraryServiceProtocol
  let watchService: WatchServiceProtocol
  let watchProgressService: WatchProgressServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel: PlaylistDetailViewModel

  init(
    playlistID: String,
    coordinator: RootCoordinator,
    libraryService: LibraryServiceProtocol,
    watchService: WatchServiceProtocol,
    watchProgressService: WatchProgressServiceProtocol,
    watchActionsService: WatchActionsServiceProtocol
  ) {
    self.playlistID = playlistID
    self.coordinator = coordinator
    self.libraryService = libraryService
    self.watchService = watchService
    self.watchProgressService = watchProgressService
    self.watchActionsService = watchActionsService
    _viewModel = StateObject(
      wrappedValue: PlaylistDetailViewModel(playlistID: playlistID, service: libraryService)
    )
  }

  var body: some View {
    Group {
      if viewModel.isLoading && viewModel.playlist == nil {
        ProgressView("Loading playlist...")
      } else if let errorMessage = viewModel.errorMessage {
        ContentUnavailableView(
          "Unable to load playlist",
          systemImage: "exclamationmark.triangle",
          description: Text(errorMessage)
        )
      } else if let playlist = viewModel.playlist {
        List {
          Section("Details") {
            TextField("Name", text: $viewModel.editedName)
            TextField("Description", text: $viewModel.editedDescription, axis: .vertical)
              .lineLimit(2...5)
            Button(viewModel.isMutating ? "Saving..." : "Save details") {
              Task { await viewModel.saveDetails() }
            }
            .disabled(viewModel.isMutating)
          }

          if let infoMessage = viewModel.infoMessage {
            Text(infoMessage)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          if !playlist.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(playlist.description)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          ForEach(playlist.videos) { video in
            NavigationLink {
              WatchView(
                videoURL: video.url,
                coordinator: coordinator,
                watchService: watchService,
                watchProgressService: watchProgressService,
                watchActionsService: watchActionsService
              )
            } label: {
              PlaylistVideoRowView(item: video)
            }
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                Task { await viewModel.remove(video: video) }
              } label: {
                Label("Remove", systemImage: "trash")
              }
            }
          }
        }
        .listStyle(.plain)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button(role: .destructive) {
              Task {
                await viewModel.deletePlaylist()
                if viewModel.currentPlaylistID == nil {
                  dismiss()
                }
              }
            } label: {
              Image(systemName: "trash")
            }
          }
        }
      }
    }
    .navigationTitle("Playlist")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.load()
    }
  }
}
