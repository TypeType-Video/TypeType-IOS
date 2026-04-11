import SwiftUI

struct LibraryView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: LibraryViewModel

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: LibraryViewModel(service: coordinator.dependencies.libraryService)
    )
  }

  @ViewBuilder
  private var content: some View {
    if let errorMessage = viewModel.errorMessage {
      Text(errorMessage)
        .font(.footnote)
        .foregroundStyle(.red)
        .padding(.horizontal)
    }

    Picker("Mode", selection: $viewModel.mode) {
      Text("History").tag(LibraryViewModel.Mode.history)
      Text("Playlists").tag(LibraryViewModel.Mode.playlists)
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)

    switch viewModel.mode {
    case .history:
      if viewModel.isLoadingHistory && viewModel.history.isEmpty {
        ProgressView("Loading history...")
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        List(viewModel.history) { item in
          NavigationLink {
            WatchView(
              videoURL: item.url,
              watchService: coordinator.dependencies.watchService,
              watchActionsService: coordinator.dependencies.watchActionsService
            )
          } label: {
            LibraryHistoryRowView(item: item)
          }
        }
        .listStyle(.plain)
      }
    case .playlists:
      if viewModel.isLoadingPlaylists && viewModel.playlists.isEmpty {
        ProgressView("Loading playlists...")
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        List(viewModel.playlists) { playlist in
          NavigationLink {
            PlaylistDetailView(
              playlistID: playlist.id,
              libraryService: coordinator.dependencies.libraryService,
              watchService: coordinator.dependencies.watchService,
              watchActionsService: coordinator.dependencies.watchActionsService
            )
          } label: {
            LibraryPlaylistRowView(playlist: playlist)
          }
        }
        .listStyle(.plain)
      }
    }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 10) {
        content
      }
      .navigationTitle("Library")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            Task { await viewModel.refreshCurrent() }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
    }
    .task {
      await viewModel.loadIfNeeded()
    }
  }
}
