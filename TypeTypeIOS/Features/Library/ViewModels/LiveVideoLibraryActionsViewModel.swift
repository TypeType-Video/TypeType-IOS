import Foundation

@MainActor
final class LiveVideoLibraryActionsViewModel: ObservableObject {
  @Published private(set) var isLoading = true
  @Published private(set) var isBusy = false
  @Published private(set) var isFavorite = false
  @Published private(set) var isInWatchLater = false
  @Published private(set) var playlists: [LivePlaylist] = []
  @Published private(set) var message: String?
  @Published private(set) var errorMessage: String?

  let video: LiveVideoItem
  private let library: LiveLibraryServiceProtocol
  private let playlistService: LivePlaylistsServiceProtocol

  init(
    video: LiveVideoItem,
    library: LiveLibraryServiceProtocol,
    playlistService: LivePlaylistsServiceProtocol
  ) {
    self.video = video
    self.library = library
    self.playlistService = playlistService
  }

  func prepare() async {
    guard isLoading else { return }
    do {
      async let favoriteRequest = library.favorite(videoURL: video.url)
      async let watchLaterRequest = library.watchLater()
      async let playlistRequest = playlistService.playlists()
      let (favorite, watchLater, summaries) = try await (
        favoriteRequest,
        watchLaterRequest,
        playlistRequest
      )
      isFavorite = favorite != nil
      isInWatchLater = watchLater.contains { $0.url == video.url }
      var details: [LivePlaylist] = []
      for summary in summaries {
        details.append(
          try await playlistService.playlist(id: summary.id)
        )
      }
      playlists = details
    } catch is CancellationError {
      return
    } catch {
      errorMessage = text(for: error)
    }
    isLoading = false
  }

  func toggleFavorite() async {
    await perform {
      if isFavorite {
        try await library.removeFavorite(videoURL: video.url)
        isFavorite = false
        message = "Removed from Favorites"
      } else {
        _ = try await library.addFavorite(videoURL: video.url)
        isFavorite = true
        message = "Saved to Favorites"
      }
    }
  }

  func toggleWatchLater() async {
    await perform {
      if isInWatchLater {
        try await library.removeWatchLater(videoURL: video.url)
        isInWatchLater = false
        message = "Removed from Watch later"
      } else {
        _ = try await library.addWatchLater(video: video)
        isInWatchLater = true
        message = "Saved to Watch later"
      }
    }
  }

  func toggle(_ playlist: LivePlaylist) async {
    await perform {
      if playlist.videos.contains(where: { $0.url == video.url }) {
        try await playlistService.removeVideo(
          id: playlist.id,
          videoURL: video.url
        )
        message = "Removed from \(playlist.name)"
      } else {
        _ = try await playlistService.addVideo(
          id: playlist.id,
          video: video
        )
        message = "Saved to \(playlist.name)"
      }
      try await refreshPlaylist(id: playlist.id)
    }
  }

  func createPlaylist(name: String, description: String) async -> Bool {
    var succeeded = false
    await perform {
      let playlist = try await playlistService.create(
        name: name,
        description: description
      )
      _ = try await playlistService.addVideo(
        id: playlist.id,
        video: video
      )
      playlists.append(
        try await playlistService.playlist(id: playlist.id)
      )
      message = "Created \(name) and saved the video"
      succeeded = true
    }
    return succeeded
  }

  func contains(_ playlist: LivePlaylist) -> Bool {
    playlist.videos.contains { $0.url == video.url }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func refreshPlaylist(id: String) async throws {
    let refreshed = try await playlistService.playlist(id: id)
    if let index = playlists.firstIndex(where: { $0.id == id }) {
      playlists[index] = refreshed
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
      errorMessage = text(for: error)
    }
  }

  private func text(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The library could not be updated."
  }
}
