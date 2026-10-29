import SwiftUI

extension LivePlaylistsView {
  @ViewBuilder
  var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .cards, count: 4)
    case let .failed(message):
      ContentUnavailableView {
        Label("Playlists unavailable", systemImage: "wifi.exclamationmark")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") {
          Task { await viewModel.reload() }
        }
      }
    case .loaded:
      loadedContent
    }
  }

  private var loadedContent: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 30) {
        if !viewModel.saved.isEmpty {
          savedSection
        }
        librarySection
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 16)
    }
    .refreshable { await viewModel.reload() }
    .background(DemoThemeBackground().ignoresSafeArea())
  }

  private var savedSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Saved public playlists")
        .font(.headline)
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 14) {
          ForEach(viewModel.saved) { playlist in
            LiveSavedPlaylistCard(
              playlist: playlist,
              onOpen: { selectedSaved = playlist },
              onRemove: { pendingSavedDeletion = playlist }
            )
            .liveConfirmPopover(
              isPresented: Binding(
                get: { pendingSavedDeletion?.id == playlist.id },
                set: { if !$0 { pendingSavedDeletion = nil } }
              ),
              title: "Remove saved playlist?",
              message: "Only the saved reference is removed from your library.",
              confirmTitle: "Remove"
            ) {
              Task { await viewModel.removeSaved(playlist) }
              pendingSavedDeletion = nil
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  private var librarySection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Your library")
        .font(.headline)
      LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
        LiveLibraryCollectionCard(
          kind: .favorites,
          videos: viewModel.favorites,
          onOpen: { selectedCollection = .favorites }
        )
        LiveLibraryCollectionCard(
          kind: .watchLater,
          videos: viewModel.watchLater,
          onOpen: { selectedCollection = .watchLater }
        )
        ForEach(viewModel.playlists) { playlist in
          LivePlaylistCard(
            playlist: playlist,
            onOpen: { selectedPlaylist = playlist },
            onDelete: { pendingPlaylistDeletion = playlist }
          )
          .liveConfirmPopover(
            isPresented: Binding(
              get: { pendingPlaylistDeletion?.id == playlist.id },
              set: { if !$0 { pendingPlaylistDeletion = nil } }
            ),
            title: "Delete playlist?",
            message: "This action cannot be undone.",
            confirmTitle: "Delete"
          ) {
            Task { await viewModel.delete(playlist) }
            pendingPlaylistDeletion = nil
          }
        }
      }
    }
  }

  private var columns: [GridItem] {
    [
      GridItem(
        .adaptive(minimum: 150, maximum: 230),
        spacing: 16,
        alignment: .top
      ),
    ]
  }

  var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
