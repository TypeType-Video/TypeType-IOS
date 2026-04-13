import Combine
import Foundation

@MainActor
final class HomeFeedViewModel: ObservableObject {
  @Published private(set) var videos: [HomeVideoItem] = []
  @Published private(set) var continueWatching: [ContinueWatchingItem] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var isLoadingMore: Bool = false
  @Published private(set) var canLoadMore: Bool = true
  @Published var errorMessage: String?
  @Published private(set) var sourceLabel: String = "Trending"

  private let homeService: HomeFeedServiceProtocol
  private let libraryService: LibraryServiceProtocol
  private let blockedService: BlockedServiceProtocol
  private let sessionProvider: () -> SessionSnapshot?
  private var blockedChannels: Set<String> = []
  private var blockedVideos: Set<String> = []
  private var nextCursor: String?

  init(
    homeService: HomeFeedServiceProtocol,
    libraryService: LibraryServiceProtocol,
    blockedService: BlockedServiceProtocol,
    sessionProvider: @escaping () -> SessionSnapshot?
  ) {
    self.homeService = homeService
    self.libraryService = libraryService
    self.blockedService = blockedService
    self.sessionProvider = sessionProvider
  }

  func loadIfNeeded(serviceID: Int = 0) async {
    guard videos.isEmpty else { return }
    await reload(serviceID: serviceID)
  }

  func reload(serviceID: Int = 0) async {
    isLoading = true
    errorMessage = nil
    do {
      await loadBlocked()
      var fetchedVideos: [HomeVideoItem]
      if sessionProvider() != nil {
        do {
          let page = try await homeService.recommendations(serviceID: serviceID, limit: 30, nextCursor: nil)
          fetchedVideos = page.items
          nextCursor = page.nextCursor
          canLoadMore = page.hasMore && page.nextCursor != nil
          sourceLabel = "Recommended"
        } catch {
          fetchedVideos = try await homeService.trending(serviceID: serviceID)
          nextCursor = nil
          canLoadMore = false
          sourceLabel = "Trending"
        }
      } else {
        fetchedVideos = try await homeService.trending(serviceID: serviceID)
        nextCursor = nil
        canLoadMore = false
        sourceLabel = "Trending"
      }

      if sessionProvider() != nil {
        videos = BlockedFilter.apply(
          to: fetchedVideos,
          blockedChannels: blockedChannels,
          blockedVideos: blockedVideos
        )
      } else {
        videos = fetchedVideos
      }

      do {
        let historyItems = try await libraryService.history(limit: 40, offset: 0)
        continueWatching = historyItems
          .filter { $0.duration > 0 && $0.progress > 0 && $0.progress < $0.duration }
          .prefix(12)
          .map(ContinueWatchingItem.init)
      } catch {
        continueWatching = []
      }
      isLoading = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load feed."
      isLoading = false
    } catch {
      errorMessage = "Unable to load feed."
      isLoading = false
    }
  }

  func loadMore(serviceID: Int = 0) async {
    guard sessionProvider() != nil else { return }
    guard !isLoading && !isLoadingMore else { return }
    guard canLoadMore else { return }
    guard let nextCursor, !nextCursor.isEmpty else { return }

    isLoadingMore = true
    do {
      let page = try await homeService.recommendations(serviceID: serviceID, limit: 30, nextCursor: nextCursor)
      let filtered = BlockedFilter.apply(
        to: page.items,
        blockedChannels: blockedChannels,
        blockedVideos: blockedVideos
      )
      videos.append(contentsOf: filtered)
      self.nextCursor = page.nextCursor
      canLoadMore = page.hasMore && page.nextCursor != nil
      isLoadingMore = false
    } catch let error as LocalizedError {
      errorMessage = error.errorDescription ?? "Unable to load more recommendations."
      isLoadingMore = false
    } catch {
      errorMessage = "Unable to load more recommendations."
      isLoadingMore = false
    }
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
