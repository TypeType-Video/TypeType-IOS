import Foundation

@MainActor
final class ShortsViewModel: ObservableObject {
  @Published private(set) var items: [HomeVideoItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published private(set) var canLoadMore: Bool = true
  @Published var errorMessage: String?

  private let service: ShortsServiceProtocol
  private var nextCursor: String?
  private var subscriptionPage: Int = 0

  init(service: ShortsServiceProtocol) {
    self.service = service
  }

  func loadInitial(serviceID: Int) async {
    guard !isLoading else { return }
    isLoading = true
    items = []
    errorMessage = nil
    nextCursor = nil
    subscriptionPage = 0
    do {
      let recommendations = try await service.recommendations(serviceID: serviceID, cursor: nil, limit: 20)
      items = recommendations.items.filter(\.isShortFormContent)
      nextCursor = recommendations.nextCursor
      canLoadMore = recommendations.hasMore
      if items.isEmpty {
        try await loadFallback(serviceID: serviceID)
      }
      isLoading = false
    } catch {
      do {
        try await loadFallback(serviceID: serviceID)
        isLoading = false
      } catch let fallbackError as LocalizedError {
        errorMessage = fallbackError.errorDescription ?? "Unable to load shorts."
        isLoading = false
      } catch {
        errorMessage = "Unable to load shorts."
        isLoading = false
      }
    }
  }

  func loadMore(serviceID: Int) async {
    guard !isLoadingMore else { return }
    guard canLoadMore else { return }
    isLoadingMore = true
    do {
      if let nextCursor {
        let recommendations = try await service.recommendations(serviceID: serviceID, cursor: nextCursor, limit: 20)
        items += recommendations.items.filter(\.isShortFormContent)
        self.nextCursor = recommendations.nextCursor
        canLoadMore = recommendations.hasMore
      } else {
        subscriptionPage += 1
        let fallback = try await service.subscriptionShorts(
          page: subscriptionPage,
          limit: 20,
          serviceID: serviceID,
          blended: true
        )
        items += fallback.videos.filter(\.isShortFormContent)
        canLoadMore = fallback.nextPage != nil
      }
      isLoadingMore = false
    } catch {
      isLoadingMore = false
    }
  }

  private func loadFallback(serviceID: Int) async throws {
    let fallback = try await service.subscriptionShorts(page: 0, limit: 20, serviceID: serviceID, blended: true)
    items = fallback.videos.filter(\.isShortFormContent)
    canLoadMore = fallback.nextPage != nil
    nextCursor = nil
    subscriptionPage = 0
  }
}
