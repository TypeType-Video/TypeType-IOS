import Combine
import Foundation

@MainActor
final class LiveHomeViewModel: ObservableObject {
  @Published private(set) var state = State.idle
  @Published private(set) var videos: [LiveVideoItem] = []
  @Published private(set) var isLoadingMore = false
  @Published private(set) var canLoadMore = false
  @Published private(set) var selectedServiceID: Int
  @Published private(set) var continueWatching: [LiveHistoryItem] = []
  @Published private(set) var showsRecommendations = true
  @Published private(set) var showsContinueWatching = true
  @Published private(set) var offersNotInterested = false

  let services: [VideoService]

  private let service: HomeFeedServiceProtocol
  private let imagePipeline: TypeTypeImagePipeline
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
    serviceSelection: LiveServiceSelection,
    imagePipeline: TypeTypeImagePipeline = TypeTypeImagePipeline()
  ) {
    self.imagePipeline = imagePipeline
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

  func reload() async {
    let currentRequest = UUID()
    requestID = currentRequest
    state = .loading
    canLoadMore = false
    nextCursor = nil
    loadTask?.cancel()
    paginationTask?.cancel()
    // Time-boxed: one stalled request would keep reload() loading forever.
    let settingsService = self.settingsService
    let settings = (try? await Self.withTimeout(seconds: 4) {
      try await settingsService.settings()
    }) ?? LiveSettings()
    showsRecommendations = !settings.hideHomeRecommendations
    showsContinueWatching = !settings.hideContinueWatching

    let task = Self.recommendationsTask(
      service: service, serviceID: selectedServiceID, limit: pageSize, hidden: settings.hideHomeRecommendations
    )
    loadTask = task
    let historyTask = Self.continueWatchingTask(historyService: historyService, hidden: settings.hideContinueWatching)

    let recommendationsResult = await task.result
    let historyResult = await historyTask.result
    guard requestID == currentRequest else {
      return
    }
    if Task.isCancelled {
      // A restarted view task cancels reload() mid-flight, and loadIfNeeded() only starts from .idle.
      if state == .loading {
        state = .idle
      }
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
      offersNotInterested = false
      canLoadMore = false
      nextCursor = nil
      state = continueWatching.isEmpty
        ? .failed(Self.message(for: error))
        : .loaded
    }
  }

  // The feed reloads while the choice saves; a refused save brings the previous feed back.
  func selectService(_ serviceID: Int) async {
    guard services.contains(where: { $0.id == serviceID }) else { return }
    let saving = Task { await serviceSelection.select(serviceID) }
    await applyGlobalService(serviceID)
    await saving.value
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
    }
  }

  private func prefetchThumbnails(for items: [LiveVideoItem]) {
    for item in items.prefix(8) {
      guard let url = LiveImageURLResolver.resolve(item.thumbnail) else { continue }
      Task.detached(priority: .utility) { [imagePipeline] in
        _ = await imagePipeline.image(for: url, maxPixelSize: 640)
      }
    }
  }

  private func applyInitial(_ page: HomeRecommendationsPage) {
    videos = []
    offersNotInterested = page.comesFromRecommender
    append(page)
  }

  private func append(_ page: HomeRecommendationsPage) {
    videos = Self.uniqueVisibleVideos(videos + page.items)
    prefetchThumbnails(for: page.items)
    nextCursor = page.nextCursor
    canLoadMore = page.hasMore && page.nextCursor?.isEmpty == false
    state = videos.isEmpty && continueWatching.isEmpty
      ? .empty
      : .loaded
  }

}
