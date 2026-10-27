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
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("New playlist", systemImage: "plus") {
              createsPlaylist = true
            }
            .accessibilityIdentifier("live.playlists.add")
          }
        }
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
    .confirmationDialog(
      "Delete playlist?",
      isPresented: playlistDeletionBinding,
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        guard let playlist = pendingPlaylistDeletion else { return }
        Task { await viewModel.delete(playlist) }
        pendingPlaylistDeletion = nil
      }
    } message: {
      Text("This action cannot be undone.")
    }
    .confirmationDialog(
      "Remove saved playlist?",
      isPresented: savedDeletionBinding,
      titleVisibility: .visible
    ) {
      Button("Remove", role: .destructive) {
        guard let playlist = pendingSavedDeletion else { return }
        Task { await viewModel.removeSaved(playlist) }
        pendingSavedDeletion = nil
      }
    } message: {
      Text("Only the saved reference is removed from your library.")
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
