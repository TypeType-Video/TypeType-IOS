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
