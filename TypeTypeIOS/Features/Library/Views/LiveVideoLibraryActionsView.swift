import SwiftUI

/// Icon-only action row under the video: Favorite, Watch later, Playlist,
/// Share, Download — no labels, translucent circles, accent when active.
struct LiveVideoLibraryActionsView: View {
  @StateObject private var viewModel: LiveVideoLibraryActionsViewModel
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @State private var createsPlaylist = false
  @State private var presentsDownload = false

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    self.dependencies = dependencies
    _viewModel = StateObject(
      wrappedValue: LiveVideoLibraryActionsViewModel(
        video: video,
        library: dependencies.libraryService,
        playlistService: dependencies.playlistsService
      )
    )
  }

  var body: some View {
    HStack(spacing: 18) {
      iconButton(
        systemImage: viewModel.isFavorite ? "heart.fill" : "heart",
        label: viewModel.isFavorite ? "Favorited" : "Favorite",
        isActive: viewModel.isFavorite
      ) {
        Task { await viewModel.toggleFavorite() }
      }
      .accessibilityIdentifier("live.video.favorite")

      iconButton(
        systemImage: viewModel.isInWatchLater
          ? "clock.badge.checkmark"
          : "clock",
        label: viewModel.isInWatchLater ? "Saved for later" : "Watch later",
        isActive: viewModel.isInWatchLater
      ) {
        Task { await viewModel.toggleWatchLater() }
      }
      .accessibilityIdentifier("live.video.watch-later")

      playlistMenu

      if let shareURL {
        ShareLink(item: shareURL) {
          iconLabel("square.and.arrow.up", isActive: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share")
        .accessibilityIdentifier("live.video.share")
      }

      iconButton(
        systemImage: "arrow.down.circle",
        label: "Download",
        isActive: false
      ) {
        presentsDownload = true
      }
      .accessibilityIdentifier("live.video.download")

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .disabled(viewModel.isBusy)
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
    .sheet(isPresented: $presentsDownload) {
      LiveDownloadSheet(video: video, dependencies: dependencies)
    }
    .alert("Library", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .task { await viewModel.prepare() }
    .accessibilityIdentifier("live.video.library-actions")
  }

  private var playlistMenu: some View {
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
      iconLabel("rectangle.stack.badge.plus", isActive: false)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Save to playlist")
    .accessibilityIdentifier("live.video.save-playlist")
  }

  private func iconButton(
    systemImage: String,
    label: String,
    isActive: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      iconLabel(systemImage, isActive: isActive)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private func iconLabel(
    _ systemImage: String,
    isActive: Bool
  ) -> some View {
    Image(systemName: systemImage)
      .font(.body.weight(.regular))
      .foregroundStyle(isActive ? DemoTheme.accent : .primary)
      .frame(width: 44, height: 44)
      .background(
        Circle().fill(
          isActive
            ? DemoTheme.accent.opacity(0.16)
            : DemoTheme.elevatedSurface
        )
      )
      .overlay(
        Circle().strokeBorder(
          isActive
            ? DemoTheme.accent.opacity(0.35)
            : Color.primary.opacity(0.14),
          lineWidth: 1
        )
      )
  }

  private var shareURL: URL? {
    LiveShareURLBuilder.video(
      serverURL: dependencies.serverStore.selectedServer()?.baseURL,
      sourceURL: video.url
    )
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
