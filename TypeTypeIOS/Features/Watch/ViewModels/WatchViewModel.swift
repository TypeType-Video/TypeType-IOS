import Foundation

@MainActor
final class WatchViewModel: ObservableObject {
  @Published private(set) var stream: WatchStream?
  @Published private(set) var relatedVideos: [HomeVideoItem] = []
  @Published private(set) var comments: [WatchComment] = []
  @Published private(set) var resumePositionMs: Int64 = 0
  @Published private(set) var isSavingProgress: Bool = false
  @Published private(set) var isLoadingComments: Bool = false
  @Published private(set) var commentsDisabled: Bool = false
  @Published private(set) var canLoadMoreComments: Bool = true
  @Published private(set) var isLoading: Bool = false
  @Published var errorMessage: String?

  fileprivate let videoURL: String
  fileprivate let watchService: WatchServiceProtocol
  private let progressService: WatchProgressServiceProtocol
  private var commentsNextPage: String?
  fileprivate var repliesByParentID: [String: [WatchComment]] = [:]
  fileprivate var repliesNextPageByParentID: [String: String?] = [:]
  fileprivate var repliesLoadingParentIDs: Set<String> = []

  private var latestPositionMs: Int64 = 0
  private var didCompletePlayback: Bool = false
  private var shouldPersistOnDisappear: Bool = true

  init(
    videoURL: String,
    watchService: WatchServiceProtocol,
    progressService: WatchProgressServiceProtocol
  ) {
    self.videoURL = videoURL
    self.watchService = watchService
    self.progressService = progressService
  }

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    do {
      let loadedStream = try await watchService.stream(for: videoURL)
      stream = loadedStream
      relatedVideos = loadedStream.relatedStreams
      comments = []
      commentsNextPage = nil
      commentsDisabled = false
      canLoadMoreComments = true
      repliesByParentID = [:]
      repliesNextPageByParentID = [:]
      repliesLoadingParentIDs = []

      let savedProgress = try await progressService.progress(for: videoURL)?.position ?? 0
      let serverStartMs = loadedStream.startPosition * 1_000
      let candidate = max(savedProgress, serverStartMs)
      let durationMs = loadedStream.duration * 1_000
      if durationMs > 0, candidate >= 5_000, candidate < Int64(Double(durationMs) * 0.95) {
        resumePositionMs = candidate
        latestPositionMs = candidate
      } else {
        resumePositionMs = 0
        latestPositionMs = 0
      }

      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load stream."
      isLoading = false
    } catch {
      errorMessage = "Unable to load stream."
      isLoading = false
    }
  }

  func loadInitialComments() async {
    guard comments.isEmpty else { return }
    await loadMoreComments()
  }

  func loadMoreComments() async {
    guard !isLoadingComments else { return }
    if !canLoadMoreComments { return }

    isLoadingComments = true
    do {
      let page = try await watchService.comments(for: videoURL, nextPage: commentsNextPage)
      comments += page.comments
      commentsDisabled = page.commentsDisabled
      commentsNextPage = page.nextPage
      canLoadMoreComments = page.nextPage != nil
      isLoadingComments = false
    } catch {
      isLoadingComments = false
    }
  }

  func updatePlayback(positionMs: Int64) {
    latestPositionMs = max(0, positionMs)
  }

  func markCompleted() {
    didCompletePlayback = true
    latestPositionMs = 0
    resumePositionMs = 0
  }

  func pausePlayback() async {
    await saveProgress(force: false)
  }

  func persistOnDisappear() async {
    guard shouldPersistOnDisappear else { return }
    await saveProgress(force: false)
  }

  func saveProgressNow() async {
    await saveProgress(force: true)
  }

  private func saveProgress(force: Bool) async {
    guard let stream else { return }
    guard !didCompletePlayback else { return }

    let durationMs = stream.duration * 1_000
    guard durationMs > 0 else { return }

    let capped = min(latestPositionMs, durationMs)
    if !force, capped < 5_000 { return }
    if capped >= Int64(Double(durationMs) * 0.95) { return }

    isSavingProgress = true
    defer { isSavingProgress = false }
    do {
      try await progressService.saveProgress(videoURL: videoURL, position: capped)
      resumePositionMs = capped
    } catch {
      // Keep UI silent on transient progress persistence failures.
    }
  }
}
