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
  private let pageSize = 30
  private var queryTask: Task<Void, Never>?

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
      items = unique(page)
      canLoadMore = page.count == pageSize
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
      let page = try await request(offset: items.count)
      let existing = Set(items.map(\.url))
      items.append(contentsOf: page.filter {
        !existing.contains($0.url)
      })
      canLoadMore = page.count == pageSize
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

  private func unique(
    _ candidates: [LiveHistoryItem]
  ) -> [LiveHistoryItem] {
    var seen: Set<String> = []
    return candidates.filter { seen.insert($0.url).inserted }
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
