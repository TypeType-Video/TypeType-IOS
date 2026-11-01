import Foundation

@MainActor
final class LiveVideoQuickActionsViewModel: ObservableObject {
  @Published private(set) var isPrepared = false
  @Published private(set) var isFavorite = false
  @Published private(set) var isInWatchLater = false
  @Published private(set) var isWatched = false
  @Published private(set) var playlists: [LivePlaylist] = []
  @Published private(set) var isBusy = false

  let video: LiveVideoItem
  private let library: LiveLibraryServiceProtocol
  private let history: LiveHistoryServiceProtocol
  private let playlistsService: LivePlaylistsServiceProtocol
  private let contentControls: LiveContentControlsServiceProtocol
  private let hiddenVideos: LiveHiddenVideos
  private let toasts: LiveToastCenter
  private var historyItem: LiveHistoryItem?

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    library = dependencies.libraryService
    history = dependencies.historyService
    playlistsService = dependencies.playlistsService
    contentControls = dependencies.contentControlsService
    hiddenVideos = dependencies.hiddenVideos
    toasts = dependencies.toasts
  }

  func prepare() async {
    guard !isPrepared else { return }
    do {
      async let favoriteRequest = library.favorite(videoURL: video.url)
      async let watchLaterRequest = library.watchLater()
      async let playlistRequest = playlistsService.playlists()
      async let historyRequest = history.history(
        query: video.title,
        from: nil,
        to: nil,
        limit: 100,
        offset: 0
      )
      let result = try await (
        favoriteRequest,
        watchLaterRequest,
        playlistRequest,
        historyRequest
      )
      isFavorite = result.0 != nil
      isInWatchLater = result.1.contains { $0.url == video.url }
      playlists = result.2
      historyItem = result.3.first { $0.url == video.url }
      isWatched = historyItem != nil
      isPrepared = true
    } catch is CancellationError {
      return
    } catch {
      presentFailure(error)
    }
  }

  func toggleFavorite() async {
    await perform {
      if isFavorite {
        try await library.removeFavorite(videoURL: video.url)
      } else {
        _ = try await library.addFavorite(videoURL: video.url)
      }
      isFavorite.toggle()
      presentMessage(isFavorite ? "Added to Favorites" : "Removed from Favorites")
    }
  }

  func toggleWatchLater() async {
    await perform {
      if isInWatchLater {
        try await library.removeWatchLater(videoURL: video.url)
      } else {
        _ = try await library.addWatchLater(video: video)
      }
      isInWatchLater.toggle()
      presentMessage(
        isInWatchLater
          ? "Added to Watch later"
          : "Removed from Watch later"
      )
    }
  }

  func addToPlaylist(_ playlist: LivePlaylist) async {
    await perform {
      let detail = try await playlistsService.playlist(id: playlist.id)
      guard !detail.videos.contains(where: { $0.url == video.url }) else {
        presentMessage("Already in \(playlist.name)")
        return
      }
      _ = try await playlistsService.addVideo(id: playlist.id, video: video)
      presentMessage("Added to \(playlist.name)")
    }
  }

  func toggleWatched() async {
    await perform {
      if let historyItem {
        try await history.remove(id: historyItem.id)
        self.historyItem = nil
        isWatched = false
        presentMessage("Marked as unwatched")
      } else {
        let item = try await history.add(
          video: video,
          progress: max(video.duration, 0)
        )
        self.historyItem = item
        isWatched = true
        presentMessage("Marked as watched")
      }
    }
  }

  func blockVideo() async {
    await block(.blockedVideos, item: LiveContentControlItem(url: video.url), done: "Video blocked")
  }

  func blockChannel() async {
    guard !video.uploaderURL.isEmpty else { return }
    await block(
      .blockedChannels,
      item: LiveContentControlItem(
        url: video.uploaderURL,
        name: video.uploaderName,
        thumbnailURL: video.uploaderAvatarURL
      ),
      done: "Channel blocked"
    )
  }

  // Toasts go straight to the center: hiding the card removes this view model's view before the request ends.
  func presentMessage(_ value: String) {
    toasts.show(value)
  }

  private func block(_ kind: LiveContentControlKind, item: LiveContentControlItem, done: String) async {
    guard !isBusy else { return }
    hiddenVideos.hide(kind, url: item.url)
    await perform {
      do {
        _ = try await contentControls.add(kind: kind, item: item)
        presentMessage(done)
      } catch {
        hiddenVideos.show(kind, url: item.url)
        throw error
      }
    }
  }

  private func perform(
    _ operation: () async throws -> Void
  ) async {
    guard !isBusy else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      try await operation()
    } catch {
      presentFailure(error)
    }
  }

  private func presentFailure(_ error: Error) {
    toasts.show(
      (error as? LocalizedError)?.errorDescription
        ?? "The action could not be completed.",
      tone: .failure
    )
  }
}
