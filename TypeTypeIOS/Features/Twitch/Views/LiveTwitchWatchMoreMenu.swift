import SwiftUI

// Saving, sharing and the sleep timer of a Twitch page, behind one button next to Follow. Quality, audio only and
// the stream details stay in the player's options button.
struct LiveTwitchWatchMoreMenu: View {
  let video: LiveVideoItem
  let dependencies: AppDependencies
  let isLive: Bool
  var offersQueue = true
  @StateObject private var viewModel: LiveVideoLibraryActionsViewModel
  @ObservedObject private var coordinator: LivePlaybackCoordinator
  @Environment(\.liveWatchExtrasEnabled) private var extrasEnabled
  @State private var createsPlaylist = false
  @State private var presentsDownload = false
  @State private var presentsQueue = false

  init(video: LiveVideoItem, dependencies: AppDependencies, isLive: Bool, offersQueue: Bool = true) {
    self.video = video
    self.dependencies = dependencies
    self.isLive = isLive
    self.offersQueue = offersQueue
    coordinator = dependencies.playbackCoordinator
    _viewModel = StateObject(
      wrappedValue: LiveVideoLibraryActionsViewModel(
        video: video,
        library: dependencies.libraryService,
        playlistService: dependencies.playlistsService
      )
    )
  }

  var body: some View {
    Menu {
      Button(
        viewModel.isFavorite ? "Remove from Favorites" : "Add to Favorites",
        systemImage: viewModel.isFavorite ? "heart.fill" : "heart"
      ) { Task { await viewModel.toggleFavorite() } }
      Button(
        viewModel.isInWatchLater ? "Remove from Watch later" : "Watch later",
        systemImage: viewModel.isInWatchLater ? "clock.badge.checkmark" : "clock"
      ) { Task { await viewModel.toggleWatchLater() } }
      playlistMenu
      if let shareURL {
        ShareLink(item: shareURL) { Label("Share", systemImage: "square.and.arrow.up") }
      }
      if !isLive {
        Button("Download", systemImage: "arrow.down.circle") { presentsDownload = true }
      }
      LivePlaybackSleepTimerMenu(coordinator: coordinator) { Label("Sleep timer", systemImage: "timer") }
      if offersQueue, !coordinator.queue.videos.isEmpty {
        Button("Up next", systemImage: "list.and.film") { presentsQueue = true }
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.subheadline.weight(.bold))
        .foregroundStyle(.primary)
        .frame(width: 34, height: 34)
        .background(Color.secondary.opacity(0.18), in: Circle())
        .contentShape(Circle())
    }
    .disabled(viewModel.isBusy)
    .accessibilityLabel(Text("More actions"))
    .accessibilityIdentifier("live.twitch.more")
    .sheet(isPresented: $createsPlaylist) {
      LivePlaylistEditorSheet(title: "New playlist", actionTitle: "Create") { name, description in
        Task {
          if await viewModel.createPlaylist(name: name, description: description) { createsPlaylist = false }
        }
      }
    }
    .sheet(isPresented: $presentsDownload) { LiveDownloadSheet(video: video, dependencies: dependencies) }
    .sheet(isPresented: $presentsQueue) { LivePlaybackQueueSheet(coordinator: coordinator) }
    .alert("Library", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .task(id: extrasEnabled) {
      guard extrasEnabled else { return }
      await viewModel.prepare()
    }
  }

  private var playlistMenu: some View {
    Menu {
      if viewModel.playlists.isEmpty {
        Text("No custom playlists")
      } else {
        ForEach(viewModel.playlists) { playlist in
          Button(playlist.name, systemImage: viewModel.contains(playlist) ? "checkmark.circle.fill" : "circle") {
            Task { await viewModel.toggle(playlist) }
          }
        }
      }
      Divider()
      Button("New playlist...", systemImage: "plus") { createsPlaylist = true }
    } label: {
      Label("Save to playlist", systemImage: "rectangle.stack.badge.plus")
    }
  }

  private var shareURL: URL? {
    LiveShareURLBuilder.video(serverURL: dependencies.serverStore.selectedServer()?.baseURL, sourceURL: video.url)
  }

  private var errorBinding: Binding<Bool> {
    Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.dismissError() } })
  }
}
