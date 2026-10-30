import Combine
import Foundation

@MainActor
final class LiveSearchViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
  }

  @Published var query = ""
  @Published private(set) var submittedQuery = ""
  @Published private(set) var state = State.idle
  @Published private(set) var results: [LiveSearchResult] = []
  @Published var filters = LiveSearchFilters(
    contentFilters: [],
    sortFilters: []
  )
  @Published private(set) var selectedServiceID: Int
  @Published private(set) var selectedContentFilter: String?
  @Published private(set) var selectedSortFilter: String?
  @Published private(set) var isLoadingMore = false
  @Published private(set) var canLoadMore = false
  @Published private(set) var searchSuggestion: String?
  @Published private(set) var isCorrectedSearch = false
  @Published var suggestions: [String] = []
  @Published var history: [LiveSearchHistoryItem] = []

  let services: [VideoService]
  let searchService: LiveSearchServiceProtocol
  private let imagePipeline: TypeTypeImagePipeline
  let historyService: LiveSearchHistoryServiceProtocol
  private let serviceSelection: LiveServiceSelection
  private var cancellables = Set<AnyCancellable>()
  var requestID = UUID()
  var nextPage: String?
  var searchTask: Task<LiveSearchPage, Error>?
  var paginationTask: Task<LiveSearchPage, Error>?
  var suggestionTask: Task<[String], Error>?
  var historyPage = 1
  var canLoadMoreHistory = false
  var isLoadingMoreHistory = false
  init(
    searchService: LiveSearchServiceProtocol,
    historyService: LiveSearchHistoryServiceProtocol,
    serviceSelection: LiveServiceSelection,
    imagePipeline: TypeTypeImagePipeline = TypeTypeImagePipeline()
  ) {
    self.imagePipeline = imagePipeline
    self.searchService = searchService
    self.historyService = historyService
    self.serviceSelection = serviceSelection
    services = serviceSelection.services
    selectedServiceID = serviceSelection.selectedID
    serviceSelection.$selectedID
      .removeDuplicates()
      .dropFirst()
      .sink { [weak self] serviceID in
        Task { @MainActor [weak self] in
          await self?.applyGlobalService(serviceID)
        }
      }
      .store(in: &cancellables)
  }

  func submit(_ value: String? = nil) async {
    let term = (value ?? query)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else {
      resetResults()
      return
    }
    query = term
    submittedQuery = term
    suggestions = []
    suggestionTask?.cancel()
    let currentRequest = UUID()
    requestID = currentRequest
    searchTask?.cancel()
    paginationTask?.cancel()
    state = .loading
    results = []
    canLoadMore = false
    nextPage = nil
    let task = Task {
      try await searchService.search(
        query: term,
        serviceID: selectedServiceID,
        nextPage: nil,
        contentFilter: selectedContentFilter,
        sortFilter: selectedSortFilter
      )
    }
    searchTask = task
    do {
      async let historyUpdate: Void = record(term)
      let page = try await task.value
      guard requestID == currentRequest, !Task.isCancelled else {
        return
      }
      applyInitial(page)
      _ = await historyUpdate
    } catch is CancellationError {
      return
    } catch {
      guard requestID == currentRequest else { return }
      state = .failed(LiveSearchResultMapper.message(for: error))
    }
  }

  func loadMore() async {
    guard canLoadMore, !isLoadingMore else { return }
    guard let nextPage, !nextPage.isEmpty else { return }
    let currentRequest = requestID
    isLoadingMore = true
    let task = Task {
      try await searchService.search(
        query: submittedQuery,
        serviceID: selectedServiceID,
        nextPage: nextPage,
        contentFilter: selectedContentFilter,
        sortFilter: selectedSortFilter
      )
    }
    paginationTask = task
    defer {
      if requestID == currentRequest {
        isLoadingMore = false
      }
    }
    do {
      let page = try await task.value
      guard requestID == currentRequest, !Task.isCancelled else {
        return
      }
      append(page)
    } catch is CancellationError {
      return
    } catch {
      guard requestID == currentRequest else { return }
      canLoadMore = true
    }
  }

  func selectService(_ serviceID: Int) async {
    await serviceSelection.select(serviceID)
    await applyGlobalService(serviceSelection.selectedID)
  }

  private func applyGlobalService(_ serviceID: Int) async {
    guard selectedServiceID != serviceID else { return }
    requestID = UUID()
    searchTask?.cancel()
    paginationTask?.cancel()
    selectedServiceID = serviceID
    selectedContentFilter = nil
    selectedSortFilter = nil
    await loadFilters()
    if !submittedQuery.isEmpty {
      await submit(submittedQuery)
    }
  }

  func selectContentFilter(_ value: String?) async {
    guard selectedContentFilter != value else { return }
    selectedContentFilter = value
    if !submittedQuery.isEmpty {
      await submit(submittedQuery)
    }
  }

  func selectSortFilter(_ value: String?) async {
    guard selectedSortFilter != value else { return }
    selectedSortFilter = value
    if !submittedQuery.isEmpty {
      await submit(submittedQuery)
    }
  }
  private func prefetchThumbnails() {
    for result in results.prefix(10) {
      guard case let .video(item) = result,
        let url = LiveImageURLResolver.resolve(item.thumbnail)
      else { continue }
      Task.detached(priority: .utility) { [imagePipeline] in
        _ = await imagePipeline.image(for: url, maxPixelSize: 640)
      }
    }
  }

  private func applyInitial(_ page: LiveSearchPage) {
    results = LiveSearchResultMapper.uniqueVisibleResults(from: page)
    prefetchThumbnails()
    updatePageMetadata(page)
    state = results.isEmpty ? .empty : .loaded
  }

  private func append(_ page: LiveSearchPage) {
    results = LiveSearchResultMapper.unique(
      results + LiveSearchResultMapper.results(from: page)
    )
    prefetchThumbnails()
    updatePageMetadata(page)
    state = results.isEmpty ? .empty : .loaded
  }

  private func updatePageMetadata(_ page: LiveSearchPage) {
    nextPage = page.nextPage
    canLoadMore = page.nextPage?.isEmpty == false
    searchSuggestion = page.searchSuggestion
    isCorrectedSearch = page.isCorrectedSearch
  }

  func resetResults() {
    requestID = UUID()
    searchTask?.cancel()
    paginationTask?.cancel()
    submittedQuery = ""
    results = []
    nextPage = nil
    canLoadMore = false
    state = .idle
  }
}
