import Foundation

@MainActor
final class LivePlaylistDetailViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  enum Sort: String, CaseIterable, Identifiable {
    case manual
    case addedNewest
    case addedOldest
    case title

    var id: String { rawValue }

    var title: String {
      switch self {
      case .manual: return String(localized: "Manual")
      case .addedNewest: return String(localized: "Recently added")
      case .addedOldest: return String(localized: "Oldest added")
      case .title: return String(localized: "Title")
      }
    }
  }

  @Published private(set) var state = State.idle
  @Published private(set) var playlist: LivePlaylist?
  @Published var sort = Sort.manual
  @Published private(set) var errorMessage: String?

  private let id: String
  private let service: LivePlaylistsServiceProtocol

  init(
    id: String,
    seed: LivePlaylist? = nil,
    service: LivePlaylistsServiceProtocol
  ) {
    self.id = id
    _playlist = Published(initialValue: seed)
    self.service = service
  }

  var videos: [LivePlaylistVideo] {
    guard let playlist else { return [] }
    switch sort {
    case .manual:
      return playlist.videos.sorted { $0.position < $1.position }
    case .addedNewest:
      return playlist.videos.sorted { $0.addedAt > $1.addedAt }
    case .addedOldest:
      return playlist.videos.sorted { $0.addedAt < $1.addedAt }
    case .title:
      return playlist.videos.sorted {
        $0.title.localizedCaseInsensitiveCompare($1.title)
          == .orderedAscending
      }
    }
  }

  func prepare() async {
    guard state == .idle else { return }
    // The list already carries the playlist (videos included): render it at
    // once and revalidate in the background. The detail request is the slow
    // one, and the page used to sit on skeletons until it landed.
    if playlist != nil {
      state = .loaded
    }
    await reload()
  }

  func reload() async {
    // Keep already visible content on screen while revalidating — only a
    // page with nothing to show falls back to the skeleton.
    let hadContent = playlist != nil
    if !hadContent {
      state = .loading
    }
    do {
      playlist = try await service.playlist(id: id)
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      if !hadContent {
        state = .failed(message(for: error))
      }
    }
  }

  func rename(name: String, description: String) async -> Bool {
    do {
      try await service.update(
        id: id,
        name: name,
        description: description
      )
      await reload()
      return true
    } catch {
      errorMessage = message(for: error)
      return false
    }
  }

  func delete() async -> Bool {
    do {
      try await service.delete(id: id)
      return true
    } catch {
      errorMessage = message(for: error)
      return false
    }
  }

  func remove(_ video: LivePlaylistVideo) async {
    do {
      try await service.removeVideo(id: id, videoURL: video.url)
      await reload()
    } catch {
      errorMessage = message(for: error)
    }
  }

  func move(from source: IndexSet, to destination: Int) async {
    guard sort == .manual else { return }
    var reordered = videos
    reordered.move(fromOffsets: source, toOffset: destination)
    do {
      try await service.reorder(
        id: id,
        videoURLs: reordered.map(\.url)
      )
      await reload()
    } catch {
      errorMessage = message(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "The playlist could not be updated."
  }
}
