import Foundation

@MainActor
final class LivePlaylistsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var playlists: [LivePlaylist] = []
  @Published private(set) var saved: [LiveSavedPlaylist] = []
  @Published private(set) var favorites: [LiveLibraryVideo] = []
  @Published private(set) var watchLater: [LiveLibraryVideo] = []
  @Published private(set) var errorMessage: String?

  private let playlistsService: LivePlaylistsServiceProtocol
  private let libraryService: LiveLibraryServiceProtocol

  init(
    playlistsService: LivePlaylistsServiceProtocol,
    libraryService: LiveLibraryServiceProtocol
  ) {
    self.playlistsService = playlistsService
    self.libraryService = libraryService
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      async let playlistsRequest = playlistsService.playlists()
      async let savedRequest = playlistsService.savedPlaylists()
      async let favoritesRequest = libraryService.favorites()
      async let watchLaterRequest = libraryService.watchLater()
      let result = try await (
        playlistsRequest,
        savedRequest,
        favoritesRequest,
        watchLaterRequest
      )
      playlists = result.0
      saved = result.1
      favorites = result.2.map(\.libraryVideo)
      watchLater = result.3.map(\.libraryVideo)
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func create(name: String, description: String) async -> Bool {
    do {
      let playlist = try await playlistsService.create(
        name: name,
        description: description
      )
      playlists.append(playlist)
      return true
    } catch {
      errorMessage = message(for: error)
      return false
    }
  }

  func delete(_ playlist: LivePlaylist) async {
    do {
      try await playlistsService.delete(id: playlist.id)
      playlists.removeAll { $0.id == playlist.id }
    } catch {
      errorMessage = message(for: error)
    }
  }

  func removeSaved(_ playlist: LiveSavedPlaylist) async {
    do {
      try await playlistsService.removeSaved(id: playlist.id)
      saved.removeAll { $0.id == playlist.id }
    } catch {
      errorMessage = message(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Playlists could not be updated."
  }
}
