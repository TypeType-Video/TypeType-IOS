import Foundation

// Kept above the rows: a lazy list rebuilds a row that scrolled away, and state held by the row would collapse it.
@MainActor
final class LiveCommentThreads: ObservableObject {
  struct Thread {
    var replies: [LiveCommentItem] = []
    var nextPage: String?
    var isLoading = false
    var isVisible = false
    var errorMessage: String?
  }

  @Published private(set) var threads: [String: Thread] = [:]

  private let videoURL: String
  private let service: LiveCommentsServiceProtocol

  init(videoURL: String, service: LiveCommentsServiceProtocol) {
    self.videoURL = videoURL
    self.service = service
  }

  func thread(for comment: LiveCommentItem) -> Thread {
    threads[comment.id] ?? Thread()
  }

  func toggle(_ comment: LiveCommentItem) async {
    var thread = thread(for: comment)
    guard thread.isVisible || !thread.replies.isEmpty else {
      await load(comment, reset: true)
      return
    }
    thread.isVisible.toggle()
    threads[comment.id] = thread
  }

  func loadMore(_ comment: LiveCommentItem) async {
    await load(comment, reset: false)
  }

  private func load(_ comment: LiveCommentItem, reset: Bool) async {
    var thread = thread(for: comment)
    let pageToken = reset ? comment.repliesPage : thread.nextPage
    guard !thread.isLoading, let pageToken, !pageToken.isEmpty else { return }
    thread.isLoading = true
    thread.errorMessage = nil
    threads[comment.id] = thread
    do {
      let page = try await service.replies(url: videoURL, repliesPage: pageToken)
      var loaded = self.thread(for: comment)
      if reset {
        loaded.replies = page.comments
      } else {
        let existing = Set(loaded.replies.map(\.id))
        loaded.replies.append(contentsOf: page.comments.filter { !existing.contains($0.id) })
      }
      loaded.nextPage = page.nextPage
      loaded.isVisible = true
      loaded.isLoading = false
      threads[comment.id] = loaded
    } catch {
      var failed = self.thread(for: comment)
      failed.isLoading = false
      failed.errorMessage = (error as? LocalizedError)?.errorDescription
        ?? String(localized: "Replies could not be loaded.")
      threads[comment.id] = failed
    }
  }
}
