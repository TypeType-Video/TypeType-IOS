import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
  @Published var query: String = ""
  @Published private(set) var items: [HomeVideoItem] = []
  @Published private(set) var nextPage: String?
  @Published private(set) var suggestion: String?
  @Published private(set) var isCorrected: Bool = false
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published var errorMessage: String?

  private let searchService: SearchServiceProtocol

  init(searchService: SearchServiceProtocol) {
    self.searchService = searchService
  }

  var canLoadMore: Bool {
    nextPage != nil && !isLoading && !isLoadingMore
  }

  func performSearch(serviceID: Int = 0) async {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      items = []
      nextPage = nil
      suggestion = nil
      isCorrected = false
      errorMessage = nil
      return
    }
    isLoading = true
    errorMessage = nil
    do {
      let response = try await searchService.search(query: trimmed, serviceID: serviceID, nextPage: nil)
      items = response.items
      nextPage = response.nextpage
      suggestion = response.searchSuggestion
      isCorrected = response.isCorrectedSearch
      isLoading = false
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
      items.append(contentsOf: response.items)
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
