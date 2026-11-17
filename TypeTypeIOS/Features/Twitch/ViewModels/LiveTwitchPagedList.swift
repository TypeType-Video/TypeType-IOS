import Foundation

@MainActor
final class LiveTwitchPagedList<Item: Identifiable & Decodable>: ObservableObject where Item.ID: Hashable {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var items: [Item] = []
  @Published private(set) var isLoadingMore = false
  @Published private(set) var moreFailed = false

  private var load: (String?) async throws -> LiveTwitchPage<Item>
  private var cursor: String?
  private var hasMore = false
  private var generation = 0

  init(load: @escaping (String?) async throws -> LiveTwitchPage<Item>) {
    self.load = load
  }

  var canLoadMore: Bool { hasMore && cursor != nil && state == .loaded }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func replace(load: @escaping (String?) async throws -> LiveTwitchPage<Item>) async {
    self.load = load
    await reload()
  }

  func reload() async {
    generation += 1
    let current = generation
    state = .loading
    moreFailed = false
    do {
      let page = try await load(nil)
      guard current == generation else { return }
      items = Self.unique(page.items, after: [])
      cursor = page.cursor
      hasMore = page.hasMore
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      guard current == generation else { return }
      state = .failed(LiveTwitchFailure.message(for: error))
    }
  }

  func loadMore() async {
    guard canLoadMore, !isLoadingMore else { return }
    let current = generation
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await load(cursor)
      guard current == generation else { return }
      items += Self.unique(page.items, after: items)
      cursor = page.cursor
      hasMore = page.hasMore && !page.items.isEmpty
      moreFailed = false
    } catch {
      guard current == generation else { return }
      moreFailed = !(error is CancellationError)
    }
  }

  private static func unique(_ page: [Item], after existing: [Item]) -> [Item] {
    var seen = Set(existing.map(\.id))
    return page.filter { seen.insert($0.id).inserted }
  }
}

enum LiveTwitchFailure {
  static func message(for error: Error) -> String {
    LiveUserError(error).message ?? String(localized: "Twitch could not be loaded right now.")
  }
}
