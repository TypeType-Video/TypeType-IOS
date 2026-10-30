import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveHomeViewModelTests: XCTestCase {
  func testInitialLoadTreatsShortsAsVideosAndDeduplicatesURLs() async {
    let first = LiveVideoItemFixture.make()
    let duplicate = LiveVideoItemFixture.make(id: "duplicate")
    let short = LiveVideoItemFixture.make(
      id: "short",
      url: "https://www.youtube.com/shorts/short",
      isShort: true
    )
    let service = HomeFeedStub(
      results: [
        .success(
          HomeRecommendationsPage(
            items: [first, duplicate, short],
            nextCursor: "page-2",
            hasMore: true
          )
        ),
      ]
    )
    let viewModel = LiveHomeViewModel(
      service: service,
      historyService: HomeHistoryStub(),
      settingsService: HomeSettingsStub(),
      serviceSelection: makeSelection(supported: [0, 5])
    )

    await viewModel.loadIfNeeded()

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(viewModel.videos.map(\.id), ["video-1", "short"])
    XCTAssertTrue(viewModel.canLoadMore)
    XCTAssertEqual(service.calls.first?.serviceID, 0)
    XCTAssertEqual(service.calls.first?.intent, "auto")
    XCTAssertEqual(service.calls.first?.limit, 12)
  }

  func testPaginationUsesCursorAndDeduplicates() async {
    let first = LiveVideoItemFixture.make()
    let second = LiveVideoItemFixture.make(
      id: "video-2",
      url: "https://www.youtube.com/watch?v=video-2"
    )
    let service = HomeFeedStub(
      results: [
        .success(
          HomeRecommendationsPage(
            items: [first],
            nextCursor: "page-2",
            hasMore: true
          )
        ),
        .success(
          HomeRecommendationsPage(
            items: [first, second],
            nextCursor: nil,
            hasMore: false
          )
        ),
      ]
    )
    let viewModel = LiveHomeViewModel(
      service: service,
      historyService: HomeHistoryStub(),
      settingsService: HomeSettingsStub(),
      serviceSelection: makeSelection(supported: [0])
    )

    await viewModel.reload()
    await viewModel.loadMore()

    XCTAssertEqual(viewModel.videos.map(\.id), ["video-1", "video-2"])
    XCTAssertEqual(service.calls.last?.cursor, "page-2")
    XCTAssertFalse(viewModel.canLoadMore)
  }

  func testChangingServiceClearsAndReloadsFeed() async {
    let youtube = LiveVideoItemFixture.make(id: "youtube")
    let bilibili = LiveVideoItemFixture.make(
      id: "bilibili",
      url: "https://www.bilibili.com/video/BV1test"
    )
    let service = HomeFeedStub(
      results: [
        .success(
          HomeRecommendationsPage(
            items: [youtube],
            nextCursor: nil,
            hasMore: false
          )
        ),
        .success(
          HomeRecommendationsPage(
            items: [bilibili],
            nextCursor: nil,
            hasMore: false
          )
        ),
      ]
    )
    let viewModel = LiveHomeViewModel(
      service: service,
      historyService: HomeHistoryStub(),
      settingsService: HomeSettingsStub(),
      serviceSelection: makeSelection(supported: [0, 5])
    )

    await viewModel.reload()
    await viewModel.selectService(5)

    XCTAssertEqual(viewModel.selectedServiceID, 5)
    XCTAssertEqual(viewModel.videos.map(\.id), ["bilibili"])
    XCTAssertEqual(service.calls.last?.serviceID, 5)
  }

  func testContinueWatchingKeepsNewestEventPerVideo() async {
    let url = "https://www.youtube.com/watch?v=video-1"
    let older = LiveHistoryItem(
      id: "older",
      url: url,
      title: "Video",
      duration: 1_000,
      progress: 120,
      watchedAt: 100
    )
    let newest = LiveHistoryItem(
      id: "newest",
      url: url,
      title: "Video",
      duration: 1_000,
      progress: 260,
      watchedAt: 200
    )
    let service = HomeFeedStub(
      results: [
        .success(
          HomeRecommendationsPage(
            items: [],
            nextCursor: nil,
            hasMore: false
          )
        ),
      ]
    )
    let viewModel = LiveHomeViewModel(
      service: service,
      historyService: HomeHistoryStub(items: [older, newest]),
      settingsService: HomeSettingsStub(),
      serviceSelection: makeSelection(supported: [0])
    )

    await viewModel.reload()

    XCTAssertEqual(viewModel.continueWatching.map(\.id), ["newest"])
    XCTAssertEqual(viewModel.continueWatching.first?.progress, 260)
  }

  func testEmptyAndFailureAreExplicitStates() async {
    let service = HomeFeedStub(
      results: [
        .success(
          HomeRecommendationsPage(
            items: [],
            nextCursor: nil,
            hasMore: false
          )
        ),
        .failure(HomeViewModelTestError.unavailable),
      ]
    )
    let viewModel = LiveHomeViewModel(
      service: service,
      historyService: HomeHistoryStub(),
      settingsService: HomeSettingsStub(),
      serviceSelection: makeSelection(supported: [])
    )

    await viewModel.reload()
    XCTAssertEqual(viewModel.state, .empty)
    XCTAssertEqual(viewModel.services.map(\.id), [0])

    await viewModel.reload()
    guard case .failed = viewModel.state else {
      return XCTFail("Expected an explicit failure state.")
    }
  }

  func testRefusedServiceChoiceBringsThePreviousFeedBack() async {
    let service = HomeFeedStub(results: [
      .success(HomeRecommendationsPage(items: [], nextCursor: nil, hasMore: false)),
      .success(HomeRecommendationsPage(items: [], nextCursor: nil, hasMore: false)),
      .success(HomeRecommendationsPage(items: [], nextCursor: nil, hasMore: false)),
    ])
    let selection = makeSelection(supported: [0, 5], settings: HomeSettingsStub(refusesUpdates: true))
    let viewModel = LiveHomeViewModel(
      service: service,
      historyService: HomeHistoryStub(),
      settingsService: HomeSettingsStub(),
      serviceSelection: selection
    )

    await viewModel.selectService(5)

    XCTAssertEqual(viewModel.selectedServiceID, 0)
    XCTAssertEqual(selection.selectedID, 0)
    XCTAssertNotNil(selection.errorMessage)
  }

  private func makeSelection(
    supported serviceIDs: [Int],
    settings: HomeSettingsStub = HomeSettingsStub()
  ) -> LiveServiceSelection {
    let selection = LiveServiceSelection(
      settingsService: settings,
      defaults: UserDefaults(
        suiteName: "LiveHomeViewModelTests.\(UUID().uuidString)"
      )!
    )
    selection.configure(supportedServiceIDs: serviceIDs)
    return selection
  }
}

private final class HomeHistoryStub: LiveHistoryServiceProtocol {
  private let items: [LiveHistoryItem]

  init(items: [LiveHistoryItem] = []) {
    self.items = items
  }

  func history(
    query: String?,
    from: Int64?,
    to: Int64?,
    limit: Int,
    offset: Int
  ) async throws -> [LiveHistoryItem] {
    items
  }

  func add(
    video: LiveVideoItem,
    progress: Int64
  ) async throws -> LiveHistoryItem {
    LiveHistoryItem(id: video.url, url: video.url, title: video.title)
  }

  func remove(id: String) async throws {}
  func clear() async throws {}
}

private final class HomeSettingsStub: LiveSettingsServiceProtocol {
  private var value = LiveSettings()
  private let refusesUpdates: Bool

  init(refusesUpdates: Bool = false) {
    self.refusesUpdates = refusesUpdates
  }

  func settings() async throws -> LiveSettings {
    value
  }

  func update(_ settings: LiveSettings) async throws -> LiveSettings {
    if refusesUpdates { throw NetworkError.statusCode(500, nil) }
    value = settings
    return value
  }
}

private final class HomeFeedStub: HomeFeedServiceProtocol {
  struct Call {
    let serviceID: Int
    let intent: String
    let limit: Int
    let cursor: String?
  }

  private let lock = NSLock()
  private var results: [
    Result<HomeRecommendationsPage, Error>
  ]
  private var recordedCalls: [Call] = []

  init(results: [Result<HomeRecommendationsPage, Error>]) {
    self.results = results
  }

  var calls: [Call] {
    lock.withLock { recordedCalls }
  }

  func recommendations(
    serviceID: Int,
    intent: String,
    limit: Int,
    cursor: String?
  ) async throws -> HomeRecommendationsPage {
    try lock.withLock {
      recordedCalls.append(
        Call(
          serviceID: serviceID,
          intent: intent,
          limit: limit,
          cursor: cursor
        )
      )
      guard !results.isEmpty else {
        throw HomeViewModelTestError.unavailable
      }
      return try results.removeFirst().get()
    }
  }
}

private enum HomeViewModelTestError: LocalizedError {
  case unavailable

  var errorDescription: String? {
    "Recommendations are unavailable."
  }
}
