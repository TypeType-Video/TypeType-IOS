import Foundation

@MainActor
final class LiveCommentSearchViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case searching
    case results
    case empty
    case failed(String)
  }

  @Published var query = ""
  @Published private(set) var state = State.idle
  @Published private(set) var results: [LiveCommentItem] = []
  @Published private(set) var isLoadingMore = false

  private let videoURL: String
  private let service: LiveCommentsServiceProtocol
  private var cursor: String?
  private var searchedQuery = ""
  private var generation = 0

  init(videoURL: String, service: LiveCommentsServiceProtocol) {
    self.videoURL = videoURL
    self.service = service
  }

  var isActive: Bool { state != .idle }
  var canLoadMore: Bool { cursor != nil && state == .results }

  func search() async {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return clear() }
    generation += 1
    let current = generation
    searchedQuery = trimmed
    state = .searching
    do {
      let page = try await service.search(url: videoURL, query: trimmed, cursor: nil)
      guard current == generation else { return }
      results = Self.unique(page.comments, after: [])
      cursor = page.nextPage
      state = results.isEmpty ? .empty : .results
    } catch is CancellationError {
      return
    } catch {
      guard current == generation else { return }
      results = []
      cursor = nil
      state = .failed(Self.message(for: error))
    }
  }

  func loadMore() async {
    guard !isLoadingMore, let cursor, state == .results else { return }
    let current = generation
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await service.search(url: videoURL, query: searchedQuery, cursor: cursor)
      guard current == generation else { return }
      results += Self.unique(page.comments, after: results)
      self.cursor = page.nextPage
    } catch is CancellationError {
      return
    } catch {
      guard current == generation else { return }
      self.cursor = nil
    }
  }

  func clear() {
    generation += 1
    query = ""
    searchedQuery = ""
    results = []
    cursor = nil
    state = .idle
  }

  private static func unique(_ comments: [LiveCommentItem], after existing: [LiveCommentItem]) -> [LiveCommentItem] {
    var ids = Set(existing.map(\.id))
    return comments.filter { ids.insert($0.id).inserted }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription ?? String(localized: "The comments could not be searched.")
  }
}
