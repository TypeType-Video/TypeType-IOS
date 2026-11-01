extension LiveSearchViewModel {
  func loadHistory() async {
    historyPage = 1
    do {
      let items = try await historyService.history(
        page: historyPage,
        limit: 8
      )
      history = Self.uniqueHistory(items)
      canLoadMoreHistory = items.count == 8
    } catch {
      history = []
      canLoadMoreHistory = false
    }
  }

  func loadMoreHistory() async {
    guard canLoadMoreHistory, !isLoadingMoreHistory else { return }
    isLoadingMoreHistory = true
    defer { isLoadingMoreHistory = false }
    let next = historyPage + 1
    do {
      let items = try await historyService.history(
        page: next,
        limit: 8
      )
      history = Self.uniqueHistory(history + items)
      historyPage = next
      canLoadMoreHistory = items.count == 8
    } catch {
      canLoadMoreHistory = false
    }
  }

  func clearHistory() async {
    do {
      try await historyService.clear()
      history = []
      historyPage = 1
      canLoadMoreHistory = false
    } catch {
      return
    }
  }

  func deleteHistory(_ item: LiveSearchHistoryItem) async {
    guard let index = history.firstIndex(of: item) else { return }
    history.remove(at: index)
    do {
      for id in try await historyIDs(matching: item.term) {
        try await historyService.delete(id: id)
      }
    } catch {
      history.insert(item, at: min(index, history.count))
    }
  }

  // The server keeps one row per search and the list shows one per term, so every copy has to go.
  private func historyIDs(matching term: String) async throws -> [String] {
    let key = term.lowercased()
    var ids: [String] = []
    for page in 1...10 {
      let items = try await historyService.history(page: page, limit: 100)
      ids += items.filter { $0.term.lowercased() == key }.map(\.id)
      if items.count < 100 { break }
    }
    return ids
  }

  func record(_ term: String) async {
    do {
      let item = try await historyService.add(term: term)
      history = Self.uniqueHistory([item] + history)
    } catch {
      return
    }
  }

  private static func uniqueHistory(
    _ items: [LiveSearchHistoryItem]
  ) -> [LiveSearchHistoryItem] {
    var seen: Set<String> = []
    return items.filter {
      seen.insert($0.term.lowercased()).inserted
    }
  }
}
