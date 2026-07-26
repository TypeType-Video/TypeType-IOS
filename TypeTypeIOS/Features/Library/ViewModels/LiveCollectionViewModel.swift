import Foundation

@MainActor
final class LiveCollectionViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  enum Sort: String, CaseIterable, Identifiable {
    case addedNewest
    case addedOldest
    case title
    case duration

    var id: String { rawValue }

    var title: String {
      switch self {
      case .addedNewest: return "Recently added"
      case .addedOldest: return "Oldest added"
      case .title: return "Title"
      case .duration: return "Duration"
      }
    }
  }

  let kind: LiveLibraryCollectionKind
  @Published private(set) var state = State.idle
  @Published private(set) var videos: [LiveLibraryVideo] = []
  @Published var sort = Sort.addedNewest
  @Published private(set) var errorMessage: String?

  private let service: LiveLibraryServiceProtocol

  init(
    kind: LiveLibraryCollectionKind,
    service: LiveLibraryServiceProtocol
  ) {
    self.kind = kind
    self.service = service
  }

  var displayedVideos: [LiveLibraryVideo] {
    switch sort {
    case .addedNewest:
      return videos.sorted { $0.savedAt > $1.savedAt }
    case .addedOldest:
      return videos.sorted { $0.savedAt < $1.savedAt }
    case .title:
      return videos.sorted {
        $0.title.localizedCaseInsensitiveCompare($1.title)
          == .orderedAscending
      }
    case .duration:
      return videos.sorted { $0.duration > $1.duration }
    }
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    state = .loading
    do {
      switch kind {
      case .favorites:
        videos = try await service.favorites().map(\.libraryVideo)
      case .watchLater:
        videos = try await service.watchLater().map(\.libraryVideo)
      }
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func remove(_ video: LiveLibraryVideo) async {
    do {
      switch kind {
      case .favorites:
        try await service.removeFavorite(videoURL: video.url)
      case .watchLater:
        try await service.removeWatchLater(videoURL: video.url)
      }
      videos.removeAll { $0.id == video.id }
    } catch {
      errorMessage = message(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "\(kind.title) could not be updated."
  }
}
