import Foundation

@MainActor
final class ShortsViewModel: ObservableObject {
  @Published private(set) var items: [HomeVideoItem] = []
  @Published var activeIndex: Int = 0
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published private(set) var canLoadMore: Bool = true
  @Published var errorMessage: String?
  @Published private(set) var hiddenVideoURLs: Set<String> = []

  private let service: ShortsServiceProtocol
  private let blockedService: BlockedServiceProtocol
  private var nextCursor: String?
  private var subscriptionPage: Int = 0
  private var blockedChannels: Set<String> = []
  private var blockedVideos: Set<String> = []

  init(service: ShortsServiceProtocol, blockedService: BlockedServiceProtocol) {
    self.service = service
    self.blockedService = blockedService
  }

  func loadInitial(serviceID: Int) async {
    guard !isLoading else { return }
    isLoading = true
    items = []
    errorMessage = nil
    nextCursor = nil
    subscriptionPage = 0
    activeIndex = 0
    await loadBlocked()
    do {
      let recommendations = try await service.recommendations(serviceID: serviceID, cursor: nil, limit: 20)
      let candidate = recommendations.items.filter(\.isShortFormContent)
      items = await applyBlockedFilter(candidate)
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
        let filtered = await applyBlockedFilter(recommendations.items.filter(\.isShortFormContent))
        items += filtered
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
        let filtered = await applyBlockedFilter(fallback.videos.filter(\.isShortFormContent))
        items += filtered
        canLoadMore = fallback.nextPage != nil
      }
      isLoadingMore = false
    } catch {
      isLoadingMore = false
    }
  }

  func prefetchIfNeeded(activeIndex: Int, serviceID: Int) {
    let threshold = max(0, items.count - 3)
    guard activeIndex >= threshold else { return }
    Task { await loadMore(serviceID: serviceID) }
  }

  func hideCurrent(index: Int) {
    guard items.indices.contains(index) else { return }
    let video = items[index]
    hiddenVideoURLs.insert(video.url)
    items.remove(at: index)
    if items.isEmpty {
      activeIndex = 0
      return
    }
    activeIndex = min(index, items.count - 1)
  }

  private func loadFallback(serviceID: Int) async throws {
    let fallback = try await service.subscriptionShorts(page: 0, limit: 20, serviceID: serviceID, blended: true)
    items = await applyBlockedFilter(fallback.videos.filter(\.isShortFormContent))
    canLoadMore = fallback.nextPage != nil
    nextCursor = nil
    subscriptionPage = 0
  }

  private func applyBlockedFilter(_ videos: [HomeVideoItem]) async -> [HomeVideoItem] {
    BlockedFilter.apply(
      to: videos,
      blockedChannels: blockedChannels,
      blockedVideos: blockedVideos
    )
  }

  private func loadBlocked() async {
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
}
