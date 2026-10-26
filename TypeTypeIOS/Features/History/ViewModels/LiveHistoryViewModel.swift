import Foundation

@MainActor
final class LiveHistoryViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
  }

  @Published var query = ""
  @Published private(set) var filter = LiveHistoryFilter.all
  @Published private(set) var state = State.idle
  @Published private(set) var items: [LiveHistoryItem] = []
  @Published private(set) var isLoadingMore = false
  @Published private(set) var canLoadMore = false
  @Published private(set) var errorMessage: String?

  private let service: LiveHistoryServiceProtocol
  private let pageSize = 20
  private var queryTask: Task<Void, Never>?
  /// Raw items fetched from the server. The display collapses duplicates,
  /// so pagination must never advance by the visible count.
  private var fetchedCount = 0

  init(service: LiveHistoryServiceProtocol) {
    self.service = service
  }

  deinit {
    queryTask?.cancel()
  }

  func prepare() async {
    guard state == .idle else { return }
    await reload()
  }

  func setFilter(_ filter: LiveHistoryFilter) {
    self.filter = filter
    queryTask?.cancel()
    queryTask = Task { await reload() }
  }

  func queryDidChange() {
    queryTask?.cancel()
    queryTask = Task {
      do {
        try await Task.sleep(for: .milliseconds(300))
        await reload()
      } catch {
        return
      }
    }
  }

  func reload() async {
    state = .loading
    do {
      let page = try await request(offset: 0)
      try Task.checkCancellation()
      LiveWatchProgressStore.shared.seed(fromHistory: page)
      fetchedCount = page.count
      // One row per video, stamped with the LAST watch (like the web). The
      // raw offset above keeps pagination correct regardless of collapsing.
      items = collapsedToLatest(page)
      canLoadMore = !page.isEmpty
      state = .loaded
    } catch is CancellationError {
      return
    } catch {
      state = .failed(message(for: error))
    }
  }

  func loadMore() async {
    guard canLoadMore, !isLoadingMore else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }
    do {
      let page = try await request(offset: fetchedCount)
      LiveWatchProgressStore.shared.seed(fromHistory: page)
      fetchedCount += page.count
      items = collapsedToLatest(items + page)
      canLoadMore = !page.isEmpty
    } catch is CancellationError {
      return
    } catch {
      errorMessage = message(for: error)
    }
  }

  func remove(_ item: LiveHistoryItem) async {
    do {
      try await service.remove(id: item.id)
      items.removeAll { $0.id == item.id }
    } catch {
      errorMessage = message(for: error)
    }
  }

  func clear() async {
    do {
      try await service.clear()
      items.removeAll()
      canLoadMore = false
      state = .loaded
    } catch {
      errorMessage = message(for: error)
    }
  }

  func dismissError() {
    errorMessage = nil
  }

  private func request(offset: Int) async throws -> [LiveHistoryItem] {
    let range = filter.range()
    return try await service.history(
      query: query.trimmingCharacters(in: .whitespacesAndNewlines)
        .nilIfEmpty,
      from: range?.from,
      to: range?.to,
      limit: pageSize,
      offset: offset
    )
  }

  /// Keeps one entry per video: the most recent watch wins.
  private func collapsedToLatest(
    _ candidates: [LiveHistoryItem]
  ) -> [LiveHistoryItem] {
    var best: [String: LiveHistoryItem] = [:]
    for item in candidates {
      if let existing = best[item.url], existing.watchedAt >= item.watchedAt {
        continue
      }
      best[item.url] = item
    }
    return candidates
      .compactMap { best[$0.url] }
      .enumerated()
      .filter { index, item in
        candidates.firstIndex { $0.url == item.url } == index
      }
      .map(\.element)
  }

  private func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "History could not be updated."
  }
}

private extension String {
  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }
}
