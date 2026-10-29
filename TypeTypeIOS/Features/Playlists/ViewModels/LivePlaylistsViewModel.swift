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
    lastFailure = nil
    state = .loading
    // Each section shows up as soon as its own request lands, not after the slowest one.
    async let playlistsLoad: Void = load(generation, { try await self.playlistsService.playlists() }) {
      self.playlists = $0
    }
    async let savedLoad: Void = load(generation, { try await self.playlistsService.savedPlaylists() }) {
      self.saved = $0
    }
    async let favoritesLoad: Void = load(generation, { try await self.libraryService.favorites() }) {
      self.favorites = $0.map(\.libraryVideo)
    }
    async let watchLaterLoad: Void = load(generation, { try await self.libraryService.watchLater() }) {
      self.watchLater = $0.map(\.libraryVideo)
    }
    _ = await (playlistsLoad, savedLoad, favoritesLoad, watchLaterLoad)
    guard generation == reloadGeneration else { return }
    if let lastFailure, playlists.isEmpty, saved.isEmpty, favorites.isEmpty, watchLater.isEmpty {
      state = .failed(lastFailure)
    } else {
      state = .loaded
    }
  }

  private func load<Value>(
    _ generation: Int,
    _ request: () async throws -> Value,
    apply: @MainActor (Value) -> Void
  ) async {
    do {
      let value = try await request()
      guard generation == reloadGeneration else { return }
      apply(value)
      if state == .loading {
        state = .loaded
      }
    } catch is CancellationError {
      return
    } catch {
      guard generation == reloadGeneration else { return }
      lastFailure = lastFailure ?? message(for: error)
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
