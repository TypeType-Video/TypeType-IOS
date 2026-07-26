import SwiftUI

struct LiveVideoQuickActionsModifier: ViewModifier {
  @StateObject private var viewModel: LiveVideoQuickActionsViewModel
  @State private var presentsDownload = false
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  let dependencies: AppDependencies
  let onOpenChannel: (() -> Void)?
  let removeLabel: String?
  let onRemove: (() -> Void)?

  init(
    video: LiveVideoItem,
    dependencies: AppDependencies,
    onOpenChannel: (() -> Void)?,
    removeLabel: String?,
    onRemove: (() -> Void)?
  ) {
    self.dependencies = dependencies
    deArrowStore = dependencies.deArrowStore
    _viewModel = StateObject(
      wrappedValue: LiveVideoQuickActionsViewModel(
        video: video,
        dependencies: dependencies
      )
    )
    self.onOpenChannel = onOpenChannel
    self.removeLabel = removeLabel
    self.onRemove = onRemove
  }

  func body(content: Content) -> some View {
    content
      .contextMenu {
        quickActions
          .task {
            async let actions: Void = viewModel.prepare()
            async let branding: Void = deArrowStore.prepare(
              viewModel.video
            )
            _ = await (actions, branding)
          }
      } preview: {
        preview
      }
      .alert(
        "Video",
        isPresented: Binding(
          get: { viewModel.message != nil },
          set: {
            if !$0 {
              viewModel.dismissMessage()
            }
          }
        )
      ) {
        Button("OK") { viewModel.dismissMessage() }
      } message: {
        Text(viewModel.message ?? "")
      }
      .sheet(isPresented: $presentsDownload) {
        LiveDownloadSheet(
          video: viewModel.video,
          dependencies: dependencies
        )
      }
  }

  @ViewBuilder
  private var quickActions: some View {
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
          ? "clock.badge.xmark"
          : "clock.badge.plus"
      )
    }

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

    if let shareURL = URL(string: viewModel.video.url) {
      ShareLink(item: shareURL) {
        Label("Share", systemImage: "square.and.arrow.up")
      }
    }

    if let onOpenChannel, !viewModel.video.uploaderURL.isEmpty {
      Button(action: onOpenChannel) {
        Label("Open channel", systemImage: "person.crop.circle")
      }
    }

    Divider()

    Button(role: .destructive) {
      Task { await viewModel.blockVideo() }
    } label: {
      Label("Block video", systemImage: "hand.raised.slash")
    }

    if !viewModel.video.uploaderURL.isEmpty {
      Button(role: .destructive) {
        Task { await viewModel.blockChannel() }
      } label: {
        Label("Block channel", systemImage: "person.crop.circle.badge.xmark")
      }
    }
  }

  private var preview: some View {
    VStack(alignment: .leading, spacing: 10) {
      LiveRemoteImage(url: branding.thumbnailURL)
        .aspectRatio(16 / 9, contentMode: .fit)
      Text(branding.title)
        .font(.headline)
        .lineLimit(2)
        .padding([.horizontal, .bottom], 12)
    }
    .frame(width: 320)
    .background(DemoTheme.background)
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: viewModel.video)
  }
}

extension View {
  func liveVideoQuickActions(
    video: LiveVideoItem,
    dependencies: AppDependencies,
    onOpenChannel: (() -> Void)? = nil,
    removeLabel: String? = nil,
    onRemove: (() -> Void)? = nil
  ) -> some View {
    modifier(
      LiveVideoQuickActionsModifier(
        video: video,
        dependencies: dependencies,
        onOpenChannel: onOpenChannel,
        removeLabel: removeLabel,
        onRemove: onRemove
      )
    )
  }
}
