import Foundation

extension LiveSearchViewModel {
  func prepare() async {
    async let filters: Void = loadFilters()
    async let history: Void = loadHistory()
    async let trending: Void = loadTrending()
    _ = await (filters, history, trending)
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
        ) == term else {
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

  func loadTrending() async {
    let currentRequest = UUID()
    trendingRequestID = currentRequest
    let serviceID = selectedServiceID
    isLoadingTrending = true
    trendingError = nil
    trendingLimit = 8
    defer { isLoadingTrending = false }
    do {
      let values = try await searchService.trending(
        serviceID: serviceID
      )
      guard trendingRequestID == currentRequest,
        selectedServiceID == serviceID else {
        return
      }
      var seen: Set<String> = []
      trending = values.filter {
        seen.insert($0.canonicalID).inserted
      }
    } catch is CancellationError {
      return
    } catch {
      guard trendingRequestID == currentRequest else { return }
      trending = []
      trendingError = (error as? LocalizedError)?.errorDescription
        ?? "Trending videos could not be loaded."
    }
  }

  var visibleContentFilters: [LiveSearchFilterOption] {
    filters.contentFilters.filter {
      $0.label.lowercased() != "all"
    }
  }
}
