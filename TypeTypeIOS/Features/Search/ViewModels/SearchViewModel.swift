import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
  @Published var query: String = ""
  @Published var inputQuery: String = ""
  @Published private(set) var items: [HomeVideoItem] = []
  @Published private(set) var suggestions: [String] = []
  @Published private(set) var history: [SearchHistoryItem] = []
  @Published private(set) var isLoadingSuggestions: Bool = false
  @Published private(set) var isLoadingHistory: Bool = false
  @Published private(set) var nextPage: String?
  @Published private(set) var suggestion: String?
  @Published private(set) var isCorrected: Bool = false
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published var errorMessage: String?

  private let searchService: SearchServiceProtocol
  private let blockedService: BlockedServiceProtocol
  private var suggestionTask: Task<Void, Never>?
  private var blockedChannels: Set<String> = []
  private var blockedVideos: Set<String> = []

  init(searchService: SearchServiceProtocol, blockedService: BlockedServiceProtocol) {
    self.searchService = searchService
    self.blockedService = blockedService
  }

  var canLoadMore: Bool {
    nextPage != nil && !isLoading && !isLoadingMore
  }

  func refreshSearchInput(serviceID: Int) {
    suggestionTask?.cancel()
    let trimmed = inputQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      suggestions = []
      return
    }
    suggestionTask = Task {
      isLoadingSuggestions = true
      try? await Task.sleep(nanoseconds: 250_000_000)
      guard !Task.isCancelled else {
        isLoadingSuggestions = false
        return
      }
      do {
        suggestions = try await searchService.suggestions(query: trimmed, serviceID: serviceID)
        isLoadingSuggestions = false
      } catch {
        suggestions = []
        isLoadingSuggestions = false
      }
    }
  }

  func applySuggestion(_ value: String) {
    inputQuery = value
    query = value
    suggestions = []
  }

  func clearSuggestions() {
    suggestions = []
  }

  func loadHistory() async {
    guard !isLoadingHistory else { return }
    isLoadingHistory = true
    do {
      history = try await searchService.searchHistory(page: 1, limit: 12)
      isLoadingHistory = false
    } catch {
      history = []
      isLoadingHistory = false
    }
  }

  func loadBlocked() async {
    do {
      async let blockedChannelsReq = blockedService.channels()
      async let blockedVideosReq = blockedService.videos()
      let channels = try await blockedChannelsReq
      let videos = try await blockedVideosReq
      blockedChannels = Set(channels.map(\.url))
      blockedVideos = Set(videos.map(\.url))
    } catch {
      blockedChannels = []
      blockedVideos = []
    }
  }

  func addHistoryEntryIfNeeded() async {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    do {
      try await searchService.addSearchHistory(term: trimmed)
      await loadHistory()
    } catch {
      return
    }
  }

  func clearHistory() async {
    do {
      try await searchService.clearSearchHistory()
      history = []
    } catch {
      return
    }
  }

  func performSearch(serviceID: Int = 0) async {
    let trimmed = inputQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    query = trimmed
    guard !trimmed.isEmpty else {
      items = []
      nextPage = nil
      suggestion = nil
      isCorrected = false
      errorMessage = nil
      clearSuggestions()
      return
    }
    clearSuggestions()
    isLoading = true
    errorMessage = nil
    do {
      let response = try await searchService.search(query: trimmed, serviceID: serviceID, nextPage: nil)
      items = BlockedFilter.apply(
        to: response.items,
        blockedChannels: blockedChannels,
        blockedVideos: blockedVideos
      )
      nextPage = response.nextpage
      suggestion = response.searchSuggestion
      isCorrected = response.isCorrectedSearch
      isLoading = false
      await addHistoryEntryIfNeeded()
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Search failed."
      isLoading = false
    } catch {
      errorMessage = "Search failed."
      isLoading = false
    }
  }

  func loadMore(serviceID: Int = 0) async {
    guard let nextPage else { return }
    guard !isLoading && !isLoadingMore else { return }
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    isLoadingMore = true
    do {
      let response = try await searchService.search(query: trimmed, serviceID: serviceID, nextPage: nextPage)
      items.append(contentsOf: BlockedFilter.apply(
        to: response.items,
        blockedChannels: blockedChannels,
        blockedVideos: blockedVideos
      ))
      self.nextPage = response.nextpage
      suggestion = response.searchSuggestion
      isCorrected = response.isCorrectedSearch
      isLoadingMore = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load more results."
      isLoadingMore = false
    } catch {
      errorMessage = "Unable to load more results."
      isLoadingMore = false
    }
  }
}
