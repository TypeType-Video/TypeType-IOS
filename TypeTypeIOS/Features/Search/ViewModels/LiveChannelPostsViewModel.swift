import Foundation

@MainActor
final class LiveChannelPostsViewModel: ObservableObject {
  enum State: Equatable {
    case loading
    case loaded
    case empty
    case failed(String)
  }

  @Published private(set) var state = State.loading
  @Published private(set) var posts: [LiveCommunityPost] = []
  @Published private(set) var isLoadingMore = false

  private let channelURL: String
  private let service: LiveChannelServiceProtocol
  private var nextPage: String?
  private var generation = 0

  init(channelURL: String, service: LiveChannelServiceProtocol) {
    self.channelURL = channelURL
    self.service = service
  }

  var canLoadMore: Bool { nextPage != nil && state == .loaded }

  func load() async {
    generation += 1
    let current = generation
    state = .loading
    do {
      let page = try await service.posts(url: channelURL, nextPage: nil)
      guard current == generation else { return }
      posts = Self.unique(page.posts, after: [])
      nextPage = page.nextPage
      state = posts.isEmpty ? .empty : .loaded
    } catch is CancellationError {
      return
    } catch {
      guard current == generation else { return }
      state = .failed((error as? LocalizedError)?.errorDescription ?? String(localized: "The posts could not be loaded."))
    }
  }

  func loadMore() async {
    guard !isLoadingMore, let nextPage else { return }
    let current = generation
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await service.posts(url: channelURL, nextPage: nextPage)
      guard current == generation else { return }
      posts += Self.unique(page.posts, after: posts)
      self.nextPage = page.nextPage
    } catch is CancellationError {
      return
    } catch {
      guard current == generation else { return }
      self.nextPage = nil
    }
  }

  private static func unique(_ posts: [LiveCommunityPost], after existing: [LiveCommunityPost]) -> [LiveCommunityPost] {
    var ids = Set(existing.map(\.id))
    return posts.filter { ids.insert($0.id).inserted }
  }
}
