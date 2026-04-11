import SwiftUI

struct PlaylistDetailView: View {
  let playlistID: String
  let libraryService: LibraryServiceProtocol
  let watchService: WatchServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol
  @StateObject private var viewModel: PlaylistDetailViewModel

  init(
    playlistID: String,
    libraryService: LibraryServiceProtocol,
    watchService: WatchServiceProtocol,
    watchActionsService: WatchActionsServiceProtocol
  ) {
    self.playlistID = playlistID
    self.libraryService = libraryService
    self.watchService = watchService
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
          if !playlist.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(playlist.description)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          ForEach(playlist.videos) { video in
            NavigationLink {
              WatchView(
                videoURL: video.url,
                watchService: watchService,
                watchActionsService: watchActionsService
              )
            } label: {
              PlaylistVideoRowView(item: video)
            }
          }
        }
        .listStyle(.plain)
      }
    }
    .navigationTitle("Playlist")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.load()
    }
  }
}
