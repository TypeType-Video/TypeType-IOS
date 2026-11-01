import Foundation

extension LiveSearchViewModel {
  func prepare() async {
    async let filters: Void = loadFilters()
    async let history: Void = loadHistory()
    _ = await (filters, history)
  }

  func queryDidChange() {
    suggestionTask?.cancel()
    let term = query.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard !term.isEmpty, term != submittedQuery else {
      suggestions = []
      if term.isEmpty, !submittedQuery.isEmpty {
        resetResults()
      }
      return
    }
    guard LiveSearchLink.destination(for: term, serverURL: nil) == nil else {
      suggestions = []
      return
    }
    let serviceID = selectedServiceID
    let task = Task {
      try await Task.sleep(for: .milliseconds(300))
      return try await searchService.suggestions(
        query: term,
        serviceID: serviceID
      )
    }
    suggestionTask = task
    Task {
      do {
        let values = try await task.value
        guard query.trimmingCharacters(
          in: .whitespacesAndNewlines
        ) == term, submittedQuery != term else {
          return
        }
        suggestions = Array(values.prefix(8))
      } catch {
        if !Task.isCancelled {
          suggestions = []
        }
      }
    }
  }

  func loadFilters() async {
    do {
      filters = try await searchService.filters(
        serviceID: selectedServiceID
      )
    } catch {
      filters = LiveSearchFilters(
        contentFilters: [],
        sortFilters: []
      )
    }
  }

  var visibleContentFilters: [LiveSearchFilterOption] {
    filters.contentFilters.filter {
      $0.label.lowercased() != "all"
    }
  }
}
