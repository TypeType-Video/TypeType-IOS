import Combine
import Foundation

@MainActor
final class LiveHomeViewModel: ObservableObject {
  enum State: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
  }

  @Published private(set) var state = State.idle
  @Published private(set) var videos: [LiveVideoItem] = []
  @Published private(set) var isLoadingMore = false
  @Published private(set) var canLoadMore = false
  @Published private(set) var selectedServiceID: Int
  @Published private(set) var continueWatching: [LiveHistoryItem] = []
  @Published private(set) var showsRecommendations = true
  @Published private(set) var showsContinueWatching = true

  let services: [VideoService]

  private let service: HomeFeedServiceProtocol
  private let historyService: LiveHistoryServiceProtocol
  private let settingsService: LiveSettingsServiceProtocol
  private let serviceSelection: LiveServiceSelection
  private let pageSize = 12
  private var nextCursor: String?
  private var requestID = UUID()
  private var loadTask: Task<HomeRecommendationsPage, Error>?
  private var paginationTask: Task<HomeRecommendationsPage, Error>?
  private var cancellables = Set<AnyCancellable>()

  init(
    service: HomeFeedServiceProtocol,
    historyService: LiveHistoryServiceProtocol,
    settingsService: LiveSettingsServiceProtocol,
    serviceSelection: LiveServiceSelection
  ) {
    self.service = service
    self.historyService = historyService
    self.settingsService = settingsService
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

  func loadIfNeeded() async {
    guard state == .idle else { return }
    await reload()
  }

  func reload() async {
    let currentRequest = UUID()
    requestID = currentRequest
    state = .loading
    canLoadMore = false
    nextCursor = nil
    loadTask?.cancel()
    paginationTask?.cancel()
    let settings = (try? await settingsService.settings())
      ?? LiveSettings()
    showsRecommendations = !settings.hideHomeRecommendations
    showsContinueWatching = !settings.hideContinueWatching

    let serviceID = selectedServiceID
    let task = Task {
      guard !settings.hideHomeRecommendations else {
        return HomeRecommendationsPage(
          items: [],
          nextCursor: nil,
          hasMore: false
        )
      }
      return try await service.recommendations(
        serviceID: serviceID,
        intent: "auto",
        limit: pageSize,
        cursor: nil
      )
    }
    loadTask = task
    let historyTask = Task { [historyService] in
      guard !settings.hideContinueWatching else {
        return [LiveHistoryItem]()
      }
      return try await historyService.history(
        query: nil,
        from: nil,
        to: nil,
        limit: 30,
        offset: 0
      )
    }

    let recommendationsResult = await task.result
    let historyResult = await historyTask.result
    guard requestID == currentRequest, !Task.isCancelled else {
      return
    }

    if case let .success(items) = historyResult {
      continueWatching = Self.inProgress(items)
    } else {
      continueWatching = []
    }

    switch recommendationsResult {
    case let .success(page):
      applyInitial(page)
    case let .failure(error):
      videos = []
      canLoadMore = false
      nextCursor = nil
      state = continueWatching.isEmpty
        ? .failed(Self.message(for: error))
        : .loaded
    }
  }

  func selectService(_ serviceID: Int) async {
    await serviceSelection.select(serviceID)
    await applyGlobalService(serviceSelection.selectedID)
  }

  private func applyGlobalService(_ serviceID: Int) async {
    guard selectedServiceID != serviceID else { return }
    requestID = UUID()
    selectedServiceID = serviceID
    videos = []
    await reload()
  }

  func loadMore() async {
    guard showsRecommendations, canLoadMore, !isLoadingMore else {
      return
    }
    guard let cursor = nextCursor, !cursor.isEmpty else { return }
    let currentRequest = requestID
    isLoadingMore = true
    paginationTask?.cancel()
    let serviceID = selectedServiceID
    let task = Task {
      try await service.recommendations(
        serviceID: serviceID,
        intent: "auto",
        limit: pageSize,
        cursor: cursor
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

  func removeFromContinueWatching(_ item: LiveHistoryItem) async {
    do {
      try await historyService.remove(id: item.id)
      continueWatching.removeAll { $0.id == item.id }
      if continueWatching.isEmpty && videos.isEmpty {
        state = .empty
      }
    } catch {
      // The full History screen exposes destructive-action errors.
    }
  }

  private func applyInitial(_ page: HomeRecommendationsPage) {
    videos = Self.uniqueVisibleVideos(page.items)
    nextCursor = page.nextCursor
    canLoadMore = page.hasMore && page.nextCursor?.isEmpty == false
    state = videos.isEmpty && continueWatching.isEmpty
      ? .empty
      : .loaded
  }

  private func append(_ page: HomeRecommendationsPage) {
    videos = Self.uniqueVisibleVideos(videos + page.items)
    nextCursor = page.nextCursor
    canLoadMore = page.hasMore && page.nextCursor?.isEmpty == false
    state = videos.isEmpty && continueWatching.isEmpty
      ? .empty
      : .loaded
  }

  private static func inProgress(
    _ items: [LiveHistoryItem]
  ) -> [LiveHistoryItem] {
    items
      .filter { item in
        guard item.progress > 0, item.duration > 0 else {
          return false
        }
        let watched = item.duration > 60
          ? item.progress >= item.duration - 60
          : Double(item.progress) >= Double(item.duration) * 0.9
        return !watched
      }
      .sorted { $0.watchedAt > $1.watchedAt }
      .prefix(12)
      .map { $0 }
  }

  private static func uniqueVisibleVideos(
    _ candidates: [LiveVideoItem]
  ) -> [LiveVideoItem] {
    var seen: Set<String> = []
    return candidates.filter { video in
      guard !video.isShortFormContent else { return false }
      return seen.insert(video.canonicalID).inserted
    }
  }

  private static func message(for error: Error) -> String {
    (error as? LocalizedError)?.errorDescription
      ?? "Recommendations could not be loaded."
  }
}
