import Foundation

@MainActor
final class LiveCommentsViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case hidden
    case disabled
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var comments: [LiveCommentItem] = []
  @Published private(set) var isLoadingMore = false

  private let videoURL: String
  private let commentsService: LiveCommentsServiceProtocol
  private let settingsService: LiveSettingsServiceProtocol
  private var nextPage: String?

  init(
    videoURL: String,
    commentsService: LiveCommentsServiceProtocol,
    settingsService: LiveSettingsServiceProtocol
  ) {
    self.videoURL = videoURL
    self.commentsService = commentsService
    self.settingsService = settingsService
  }

  var canLoadMore: Bool {
    nextPage?.isEmpty == false
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload(ignoringPreference: Bool = false) async {
    state = .loading
    do {
      if !ignoringPreference {
        let settings = try await settingsService.settings()
        guard !settings.hideComments else {
          comments = []
          nextPage = nil
          state = .hidden
          return
        }
      }
      let page = try await commentsService.comments(
        url: videoURL,
        nextPage: nil
      )
      guard !page.commentsDisabled else {
        comments = []
        nextPage = nil
        state = .disabled
        return
      }
      comments = Self.unique(page.comments)
      nextPage = page.nextPage
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  func loadMore() async {
    guard !isLoadingMore, let nextPage, !nextPage.isEmpty else {
      return
    }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await commentsService.comments(
        url: videoURL,
        nextPage: nextPage
      )
      let existing = Set(comments.map(\.id))
      comments.append(contentsOf: Self.unique(page.comments).filter {
        !existing.contains($0.id)
      })
      self.nextPage = page.nextPage
    } catch is CancellationError {
      return
    } catch {
      state = .failed(Self.message(for: error))
    }
  }

  private static func unique(
    _ comments: [LiveCommentItem]
  ) -> [LiveCommentItem] {
    var ids: Set<String> = []
    return comments.filter { ids.insert($0.id).inserted }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Comments could not be loaded."
  }
}
