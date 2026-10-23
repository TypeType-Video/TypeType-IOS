import Foundation

@MainActor
final class LivePublicPlaylistViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var playlist: LivePlaylistResult
  @Published private(set) var videos: [LiveVideoItem] = []
  @Published private(set) var savedID: String?
  @Published private(set) var isLoadingMore = false
  @Published private(set) var isPreparingPlayback = false
  @Published private(set) var errorMessage: String?

  private let service: LivePlaylistsServiceProtocol
  private var nextPage: String?

  init(
    playlist: LivePlaylistResult,
    service: LivePlaylistsServiceProtocol
  ) {
    self.playlist = playlist
    self.service = service
  }

  var canLoadMore: Bool {
    nextPage?.isEmpty == false
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      async let pageRequest = service.publicPlaylist(
        url: playlist.url,
        nextPage: nil
      )
      async let savedRequest = service.savedPlaylists()
      let (page, saved) = try await (pageRequest, savedRequest)
      playlist = page.playlist
      videos = uniqueVisible(page.videos)
      nextPage = page.nextPage
      savedID = saved.first {
        Self.normalizedURL($0.url) == Self.normalizedURL(playlist.url)
      }?.id
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func loadMore() async {
    guard !isLoadingMore, let nextPage, !nextPage.isEmpty else {
      return
    }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await service.publicPlaylist(
        url: playlist.url,
        nextPage: nextPage
      )
      let existing = Set(videos.map(\.canonicalID))
      videos.append(contentsOf: uniqueVisible(page.videos).filter {
        !existing.contains($0.canonicalID)
      })
      self.nextPage = page.nextPage
    } catch {
      errorMessage = message(for: error)
    }
  }

  func toggleSaved() async {
    do {
      if let savedID {
        try await service.removeSaved(id: savedID)
        self.savedID = nil
      } else {
        let saved = try await service.savePublic(url: playlist.url)
        savedID = saved.id
      }
    } catch {
      errorMessage = message(for: error)
    }
  }

  func videosForPlayback() async -> [LiveVideoItem]? {
    guard !isPreparingPlayback else { return nil }
    isPreparingPlayback = true
    defer { isPreparingPlayback = false }
    do {
      var seenTokens: Set<String> = []
      while let pageToken = nextPage, !pageToken.isEmpty {
        // A cursor cycle (A -> B -> A) must not spin forever; tracking every
        // token already used breaks any repeating chain, not just an
        // immediate echo.
        guard seenTokens.insert(pageToken).inserted else { break }
        let page = try await service.publicPlaylist(
          url: playlist.url,
          nextPage: pageToken
        )
        let existing = Set(videos.map(\.canonicalID))
        videos.append(contentsOf: uniqueVisible(page.videos).filter {
          !existing.contains($0.canonicalID)
        })
        nextPage = page.nextPage
      }
      return videos
    } catch is CancellationError {
      return nil
    } catch {
      errorMessage = message(for: error)
      return nil
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private static func normalizedURL(_ value: String) -> String {
    value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      .lowercased()
  }

  private func uniqueVisible(
    _ candidates: [LiveVideoItem]
  ) -> [LiveVideoItem] {
    var seen: Set<String> = []
    return candidates.filter {
      seen.insert($0.canonicalID).inserted
    }
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The public playlist could not be updated."
  }
}
