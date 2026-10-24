import SwiftUI

struct LiveVideoLibraryActionsView: View {
  @StateObject private var viewModel: LiveVideoLibraryActionsViewModel
  @State private var createsPlaylist = false

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    _viewModel = StateObject(
      wrappedValue: LiveVideoLibraryActionsViewModel(
        video: video,
        library: dependencies.libraryService,
        playlistService: dependencies.playlistsService
      )
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if viewModel.isLoading {
        ProgressView("Loading library actions")
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            actionButton(
              title: viewModel.isFavorite ? "Favorited" : "Favorite",
              symbol: viewModel.isFavorite ? "heart.fill" : "heart",
              isActive: viewModel.isFavorite
            ) {
              Task { await viewModel.toggleFavorite() }
            }
            actionButton(
              title: viewModel.isInWatchLater ? "Saved for later" : "Watch later",
              symbol: viewModel.isInWatchLater
                ? "clock.badge.checkmark"
                : "clock",
              isActive: viewModel.isInWatchLater
            ) {
              Task { await viewModel.toggleWatchLater() }
            }
            saveToPlaylistChip
          }
        }

      }

      if let message = viewModel.message {
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .transition(.opacity)
      }
    }
    .sheet(isPresented: $createsPlaylist) {
      LivePlaylistEditorSheet(
        title: "New playlist",
        actionTitle: "Create"
      ) { name, description in
        Task {
          if await viewModel.createPlaylist(
            name: name,
            description: description
          ) {
            createsPlaylist = false
          }
        }
      }
    }
    .alert("Library", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .task { await viewModel.prepare() }
    .accessibilityIdentifier("live.video.library-actions")
  }

  private func actionButton(
    title: String,
    symbol: String,
    isActive: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: symbol)
    }
    .buttonStyle(LiveChipButtonStyle(isActive: isActive))
    .disabled(viewModel.isBusy)
  }

  private var saveToPlaylistChip: some View {
    Menu {
      if viewModel.playlists.isEmpty {
        Text("No custom playlists")
      } else {
        ForEach(viewModel.playlists) { playlist in
          Button {
            Task { await viewModel.toggle(playlist) }
          } label: {
            Label(
              playlist.name,
              systemImage: viewModel.contains(playlist)
                ? "checkmark.circle.fill"
                : "circle"
            )
          }
        }
      }
      Divider()
      Button("New playlist...", systemImage: "plus") {
        createsPlaylist = true
      }
    } label: {
      Label("Save to playlist", systemImage: "rectangle.stack.badge.plus")
    }
    .buttonStyle(LiveChipButtonStyle())
    .disabled(viewModel.isBusy)
    .accessibilityIdentifier("live.video.save-playlist")
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
