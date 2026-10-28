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
  private var reloadGeneration = 0
  private var pendingRequests = 0
  private var lastFailure: String?

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
    reloadGeneration += 1
    let generation = reloadGeneration
    pendingRequests = 4
    lastFailure = nil
    state = .loading
    // Each section appears the moment its request lands — the page no
    // longer waits for the slowest of the four before it draws anything.
    Task { [weak self] in
      guard let self else { return }
      do {
        playlists = try await playlistsService.playlists()
        revealWhileLoading()
      } catch {
        noteFailure(error)
      }
      reloadRequestFinished(generation)
    }
    Task { [weak self] in
      guard let self else { return }
      do {
        saved = try await playlistsService.savedPlaylists()
        revealWhileLoading()
      } catch {
        noteFailure(error)
      }
      reloadRequestFinished(generation)
    }
    Task { [weak self] in
      guard let self else { return }
      do {
        favorites = try await libraryService.favorites().map(\.libraryVideo)
        revealWhileLoading()
      } catch {
        noteFailure(error)
      }
      reloadRequestFinished(generation)
    }
    Task { [weak self] in
      guard let self else { return }
      do {
        watchLater = try await libraryService.watchLater().map(\.libraryVideo)
        revealWhileLoading()
      } catch {
        noteFailure(error)
      }
      reloadRequestFinished(generation)
    }
  }

  /// First data on screen beats the loading skeleton.
  private func revealWhileLoading() {
    if state == .loading {
      state = .loaded
    }
  }

  private func noteFailure(_ error: Error) {
    if error is CancellationError { return }
    if lastFailure == nil {
      lastFailure = message(for: error)
    }
  }

  private func reloadRequestFinished(_ generation: Int) {
    guard generation == reloadGeneration else { return }
    pendingRequests -= 1
    guard pendingRequests == 0 else { return }
    if let lastFailure,
      playlists.isEmpty, saved.isEmpty, favorites.isEmpty, watchLater.isEmpty {
      state = .failed(lastFailure)
    } else {
      state = .loaded
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
