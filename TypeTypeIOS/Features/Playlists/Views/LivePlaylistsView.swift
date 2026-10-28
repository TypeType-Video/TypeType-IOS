import SwiftUI

struct LivePlaylistsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @Binding var requestedCollection: LiveLibraryCollectionKind?
  @StateObject var viewModel: LivePlaylistsViewModel
  @State var selectedPlaylist: LivePlaylist?
  @State var selectedSaved: LiveSavedPlaylist?
  @State var selectedCollection: LiveLibraryCollectionKind?
  @State var pendingPlaylistDeletion: LivePlaylist?
  @State var pendingSavedDeletion: LiveSavedPlaylist?
  @State var createsPlaylist = false

  init(
    coordinator: RootCoordinator,
    requestedCollection: Binding<LiveLibraryCollectionKind?> = .constant(nil)
  ) {
    self.coordinator = coordinator
    _requestedCollection = requestedCollection
    _viewModel = StateObject(
      wrappedValue: LivePlaylistsViewModel(
        playlistsService: coordinator.dependencies.playlistsService,
        libraryService: coordinator.dependencies.libraryService
      )
    )
  }

  // No nested stack: the library pager hosts this section inside the
  // library's stack, whose bar carries the New playlist button.
  var body: some View {
    content
      .navigationTitle("Playlists")
      .navigationBarTitleDisplayMode(.inline)
          .navigationDestination(item: $selectedPlaylist) { playlist in
          LivePlaylistDetailView(
            playlist: playlist,
            dependencies: coordinator.dependencies
          ) {
            Task { await viewModel.reload() }
          }
        }
        .navigationDestination(item: $selectedSaved) { saved in
          LivePublicPlaylistView(
            playlist: saved.searchResult,
            dependencies: coordinator.dependencies
          )
        }
      .navigationDestination(item: $selectedCollection) { kind in
        LiveCollectionView(
          kind: kind,
          dependencies: coordinator.dependencies
        )
      }
    .task {
      await viewModel.prepare()
      openRequestedCollection()
    }
    .onChange(of: requestedCollection) {
      openRequestedCollection()
    }
    .sheet(isPresented: $createsPlaylist) {
      LivePlaylistEditorSheet(
        title: "New playlist",
        actionTitle: "Create"
      ) { name, description in
        Task {
          if await viewModel.create(
            name: name,
            description: description
          ) {
            createsPlaylist = false
          }
        }
      }
    }
    .alert("Playlists", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.playlists.screen")
  }

  private func openRequestedCollection() {
    guard let requestedCollection else { return }
    selectedCollection = requestedCollection
    self.requestedCollection = nil
  }
}
