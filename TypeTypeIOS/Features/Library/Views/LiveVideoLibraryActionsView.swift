import SwiftUI

/// Icon-only action row under the video: Favorite, Watch later, Playlist,
/// Share, Download: no labels, translucent circles, accent when active.
struct LiveVideoLibraryActionsView: View {
  @Environment(\.themePalette) private var palette
  @StateObject private var viewModel: LiveVideoLibraryActionsViewModel
  let video: LiveVideoItem
  let dependencies: AppDependencies
  @State private var createsPlaylist = false
  @Environment(\.liveWatchExtrasEnabled) private var extrasEnabled
  @State private var presentsDownload = false
  @State private var presentsSleepTimer = false
  @ObservedObject private var playbackCoordinator: LivePlaybackCoordinator

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    self.dependencies = dependencies
    playbackCoordinator = dependencies.playbackCoordinator
    _viewModel = StateObject(
      wrappedValue: LiveVideoLibraryActionsViewModel(
        video: video,
        library: dependencies.libraryService,
        playlistService: dependencies.playlistsService
      )
    )
  }

  var body: some View {
    // Six fixed 44 pt buttons: the 18 pt gaps alone overflowed a 375 pt iPhone and widened the whole page.
    ViewThatFits(in: .horizontal) {
      actionsRow(spacing: 18)
      actionsRow(spacing: 10)
      actionsRow(spacing: 4)
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
    .task(id: extrasEnabled) {
      guard extrasEnabled else { return }
      await viewModel.prepare()
    }
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

  private func actionsRow(spacing: CGFloat) -> some View {
    HStack(spacing: spacing) {
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
        LiveShareAsLinkButton(
          typeTypeURL: shareURL,
          originalURL: LiveShareURLBuilder.original(
            sourceURL: video.url
          )
        ) {
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

      iconButton(
        systemImage: "timer",
        label: "Sleep timer",
        isActive: playbackCoordinator.sleepTimer.isActive
      ) {
        presentsSleepTimer = true
      }
      .accessibilityIdentifier("live.video.sleep-timer")
      .popover(
        isPresented: $presentsSleepTimer,
        attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
        arrowEdge: .top
      ) {
        LivePlaybackSleepTimerPopover(coordinator: playbackCoordinator)
      }
    }
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
      .font(.title3.weight(.regular))
      .foregroundStyle(isActive ? Color.white : .primary)
      .frame(width: 44, height: 44)
      .background {
        if #available(iOS 26.0, *) {
          // Inactive takes the row colour: elevatedSurface is too dark under the glass.
          Circle()
            .fill(
              (isActive ? palette.accent : palette.rowBackground)
                .opacity(isActive ? 0.32 : 0.55)
            )
            // The washes read too dark in themes: lift the glass.
            .brightness(0.12)
            .glassEffect(
              .regular.tint(
                isActive ? palette.accent : palette.rowBackground
              ),
              in: .circle
            )
        } else {
          Circle().fill(
            isActive
              ? palette.accent.opacity(0.16)
              : palette.elevatedSurface
          )
          .overlay(
            Circle().strokeBorder(
              isActive
                ? palette.accent.opacity(0.35)
                : Color.primary.opacity(0.14),
              lineWidth: 1
            )
          )
        }
      }
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
