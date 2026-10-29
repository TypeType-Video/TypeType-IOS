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
      case .addedNewest: return String(localized: "Recently added")
      case .addedOldest: return String(localized: "Oldest added")
      case .title: return String(localized: "Title")
      case .duration: return String(localized: "Duration")
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
    seed: [LiveLibraryVideo] = [],
    service: LiveLibraryServiceProtocol
  ) {
    self.kind = kind
    _videos = Published(initialValue: seed)
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
    // The lists carrying this collection already hold its videos: render
    // at once and revalidate behind (the library requests are the slow
    // ones — the page used to sit on skeletons until they landed).
    if !videos.isEmpty {
      state = .loaded
    }
    await reload()
  }

  func reload() async {
    let startedAt = DispatchTime.now().uptimeNanoseconds
    // Keep already visible content on screen while revalidating.
    let hadContent = !videos.isEmpty
    if !hadContent {
      state = .loading
    }
    do {
      switch kind {
      case .favorites:
        videos = try await service.favorites().map(\.libraryVideo)
      case .watchLater:
        videos = try await service.watchLater().map(\.libraryVideo)
      }
      state = .loaded
      let ms = Int(
        Double(DispatchTime.now().uptimeNanoseconds - startedAt) / 1e6
      )
      AppLogger.playback.info(
        "collection: \(String(describing: kind), privacy: .public) loaded count=\(videos.count, privacy: .public) in \(ms, privacy: .public)ms"
      )
    } catch is CancellationError {
      return
    } catch {
      AppLogger.playback.error(
        "collection: \(String(describing: kind), privacy: .public) failed \(error.localizedDescription, privacy: .public)"
      )
      if !hadContent {
        state = .failed(message(for: error))
      }
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
