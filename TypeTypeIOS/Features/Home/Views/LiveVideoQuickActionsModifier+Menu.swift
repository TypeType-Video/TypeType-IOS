import SwiftUI

extension LiveVideoQuickActionsModifier {
  @ViewBuilder
  var quickActions: some View {
    if playbackCoordinator.hasActivePlayback,
      playbackCoordinator.currentVideo?.url != viewModel.video.url {
      playbackQueueActions
      Divider()
    }

    Button {
      Task { await viewModel.toggleFavorite() }
    } label: {
      Label(
        viewModel.isFavorite
          ? "Remove from Favorites"
          : "Add to Favorites",
        systemImage: viewModel.isFavorite ? "heart.slash" : "heart"
      )
    }

    Button {
      Task { await viewModel.toggleWatchLater() }
    } label: {
      Label(
        viewModel.isInWatchLater
          ? "Remove from Watch later"
          : "Add to Watch later",
        systemImage: viewModel.isInWatchLater
          ? "clock.arrow.circlepath"
          : "clock"
      )
    }

    playlistMenu

    Button {
      Task { await viewModel.toggleWatched() }
    } label: {
      Label(
        viewModel.isWatched ? "Mark as unwatched" : "Mark as watched",
        systemImage: viewModel.isWatched
          ? "eye.slash"
          : "checkmark.circle"
      )
    }

    Button {
      presentsDownload = true
    } label: {
      Label("Download", systemImage: "arrow.down.circle")
    }

    if let removeLabel, let onRemove {
      Button(role: .destructive, action: onRemove) {
        Label(removeLabel, systemImage: "trash")
      }
    }

    if LiveShareURLBuilder.video(
      serverURL: dependencies.serverStore.selectedServer()?.baseURL,
      sourceURL: viewModel.video.url
    ) != nil {
      // The popover tears down its content on tap: the dialog and share sheet live on the modifier body.
      Button {
        presentsShareChoice = true
      } label: {
        Label("Share", systemImage: "square.and.arrow.up")
      }
    }

    if let onOpenChannel, !viewModel.video.uploaderURL.isEmpty {
      Button(action: onOpenChannel) {
        Label("Open channel", systemImage: "person.crop.circle")
      }
    }

    Divider()
    blockingActions
  }

  @ViewBuilder
  private var playbackQueueActions: some View {
    Button {
      presentQueueResult(
        playbackCoordinator.enqueue(
          viewModel.video,
          playNext: true
        )
      )
    } label: {
      Label("Play next", systemImage: "text.insert")
    }

    if playbackCoordinator.isQueued(viewModel.video) {
      Button {
        playbackCoordinator.remove(viewModel.video)
        viewModel.presentMessage("Removed from playback queue")
      } label: {
        Label(
          "Remove from queue",
          systemImage: "text.badge.minus"
        )
      }
    } else {
      Button {
        presentQueueResult(
          playbackCoordinator.enqueue(
            viewModel.video,
            playNext: false
          )
        )
      } label: {
        Label("Add to queue", systemImage: "text.badge.plus")
      }
    }
  }

  private var playlistMenu: some View {
    Menu {
      if viewModel.playlists.isEmpty {
        Text(
          viewModel.isPrepared
            ? "No custom playlists"
            : "Loading playlists..."
        )
      } else {
        ForEach(viewModel.playlists) { playlist in
          Button(playlist.name, systemImage: "rectangle.stack.badge.plus") {
            Task { await viewModel.addToPlaylist(playlist) }
          }
        }
      }
    } label: {
      Label("Add to playlist", systemImage: "rectangle.stack.badge.plus")
    }
  }

  @ViewBuilder
  private var blockingActions: some View {
    Button(role: .destructive) {
      Task { await viewModel.blockVideo() }
    } label: {
      Label("Block video", systemImage: "hand.raised.slash")
    }

    if !viewModel.video.uploaderURL.isEmpty {
      Button(role: .destructive) {
        Task { await viewModel.blockChannel() }
      } label: {
        Label(
          "Block channel",
          systemImage: "person.crop.circle.badge.xmark"
        )
      }
    }
  }
}
