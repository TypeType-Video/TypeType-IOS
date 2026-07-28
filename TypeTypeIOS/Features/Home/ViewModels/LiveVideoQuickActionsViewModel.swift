import Foundation

@MainActor
final class LiveVideoQuickActionsViewModel: ObservableObject {
  @Published private(set) var isPrepared = false
  @Published private(set) var isFavorite = false
  @Published private(set) var isInWatchLater = false
  @Published private(set) var isWatched = false
  @Published private(set) var playlists: [LivePlaylist] = []
  @Published private(set) var isBusy = false
  @Published private(set) var message: String?

  let video: LiveVideoItem
  private let library: LiveLibraryServiceProtocol
  private let history: LiveHistoryServiceProtocol
  private let playlistsService: LivePlaylistsServiceProtocol
  private let contentControls: LiveContentControlsServiceProtocol
  private var historyItem: LiveHistoryItem?

  init(video: LiveVideoItem, dependencies: AppDependencies) {
    self.video = video
    library = dependencies.libraryService
    history = dependencies.historyService
    playlistsService = dependencies.playlistsService
    contentControls = dependencies.contentControlsService
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
      message = text(for: error)
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
      message = isFavorite ? "Added to Favorites" : "Removed from Favorites"
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
      message = isInWatchLater
        ? "Added to Watch later"
        : "Removed from Watch later"
    }
  }

  func addToPlaylist(_ playlist: LivePlaylist) async {
    await perform {
      let detail = try await playlistsService.playlist(id: playlist.id)
      guard !detail.videos.contains(where: { $0.url == video.url }) else {
        message = "Already in \(playlist.name)"
        return
      }
      _ = try await playlistsService.addVideo(id: playlist.id, video: video)
      message = "Added to \(playlist.name)"
    }
  }

  func toggleWatched() async {
    await perform {
      if let historyItem {
        try await history.remove(id: historyItem.id)
        self.historyItem = nil
        isWatched = false
        message = "Marked as unwatched"
      } else {
        let item = try await history.add(
          video: video,
          progress: max(video.duration, 0)
        )
        self.historyItem = item
        isWatched = true
        message = "Marked as watched"
      }
    }
  }

  func blockVideo() async {
    await perform {
      _ = try await contentControls.add(
        kind: .blockedVideos,
        item: LiveContentControlItem(url: video.url)
      )
      message = "Video blocked"
    }
  }

  func blockChannel() async {
    guard !video.uploaderURL.isEmpty else { return }
    await perform {
      _ = try await contentControls.add(
        kind: .blockedChannels,
        item: LiveContentControlItem(
          url: video.uploaderURL,
          name: video.uploaderName,
          thumbnailURL: video.uploaderAvatarURL
        )
      )
      message = "Channel blocked"
    }
  }

  func dismissMessage() {
    message = nil
  }

  func presentMessage(_ value: String) {
    message = value
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
      message = text(for: error)
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The action could not be completed."
  }
}
