import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveSearchViewModelTests: XCTestCase {
  func testPrepareLoadsFiltersAndServerHistory() async {
    let search = SearchServiceStub(pages: [])
    let history = SearchHistoryStub(
      items: [
        LiveSearchHistoryItem(id: "one", term: "SABR", searchedAt: 1),
      ]
    )
    let viewModel = makeViewModel(search: search, history: history)

    await viewModel.prepare()

    XCTAssertEqual(
      viewModel.visibleContentFilters.map(\.displayName),
      ["Videos"]
    )
    XCTAssertEqual(viewModel.history.map(\.term), ["SABR"])
    XCTAssertEqual(search.filterServices, [0])
  }

  func testSearchUsesMixedResultsIncludesShortsAndRecordsHistory() async {
    let video = LiveVideoItemFixture.make(
      id: "video",
      url: "https://www.youtube.com/watch?v=video"
    )
    let short = LiveVideoItemFixture.make(id: "short", isShort: true)
    let search = SearchServiceStub(
      pages: [
        LiveSearchPage(
          items: [video, short],
          nextPage: "page-2",
          searchSuggestion: "Big Buck Bunny",
          isCorrectedSearch: false,
          playlists: [Self.playlist],
          channels: [Self.channel]
        ),
      ]
    )
    let history = SearchHistoryStub(items: [])
    let viewModel = makeViewModel(search: search, history: history)

    await viewModel.submit("Big Buck Bunny")

    XCTAssertEqual(
      viewModel.results.map(\.id),
      [
        "channel:https://youtube.test/channel",
        "playlist:https://youtube.test/playlist",
        "video:https://www.youtube.com/watch?v=video",
        "video:https://www.youtube.com/watch?v=video-1",
      ]
    )
    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertTrue(viewModel.canLoadMore)
    XCTAssertEqual(history.addedTerms, ["Big Buck Bunny"])
    XCTAssertEqual(viewModel.history.first?.term, "Big Buck Bunny")
  }

  func testPaginationUsesOpaqueNextPageAndDeduplicates() async {
    let first = LiveVideoItemFixture.make(
      id: "first",
      url: "https://www.youtube.com/watch?v=first"
    )
    let second = LiveVideoItemFixture.make(
      id: "second",
      url: "https://www.youtube.com/watch?v=second"
    )
    let search = SearchServiceStub(
      pages: [
        LiveSearchPage(
          items: [first],
          nextPage: "opaque",
          searchSuggestion: nil,
          isCorrectedSearch: false,
          playlists: [],
          channels: []
        ),
        LiveSearchPage(
          items: [first, second],
          nextPage: nil,
          searchSuggestion: nil,
          isCorrectedSearch: false,
          playlists: [],
          channels: []
        ),
      ]
    )
    let viewModel = makeViewModel(
      search: search,
      history: SearchHistoryStub(items: [])
    )

    await viewModel.submit("TypeType")
    await viewModel.loadMore()

    XCTAssertEqual(
      viewModel.results.map(\.id),
      [
        "video:https://www.youtube.com/watch?v=first",
        "video:https://www.youtube.com/watch?v=second",
      ]
    )
    XCTAssertEqual(search.calls.last?.nextPage, "opaque")
    XCTAssertFalse(viewModel.canLoadMore)
  }

  func testSearchResultsDoNotWaitForHistoryRecording() async {
    let video = LiveVideoItemFixture.make(
      id: "video",
      url: "https://www.youtube.com/watch?v=video"
    )
    let search = SearchServiceStub(
      pages: [
        LiveSearchPage(
          items: [video],
          nextPage: nil,
          searchSuggestion: nil,
          isCorrectedSearch: false,
          playlists: [],
          channels: []
        ),
      ]
    )
    let history = SearchHistoryStub(
      items: [],
      addDelay: .seconds(5)
    )
    let viewModel = makeViewModel(search: search, history: history)

    let submission = Task {
      await viewModel.submit("resilient search")
    }
    for _ in 0..<100 where viewModel.state != .loaded {
      try? await Task.sleep(for: .milliseconds(5))
    }

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertEqual(viewModel.results.count, 1)
    submission.cancel()
    await submission.value
  }

  func testSharedServiceSelectionUpdatesSearchDiscovery() async {
    let search = SearchServiceStub(pages: [])
    let selection = makeSelection()
    let viewModel = makeViewModel(
      search: search,
      history: SearchHistoryStub(items: []),
      selection: selection
    )

    await viewModel.prepare()
    await selection.select(5)
    for _ in 0..<50
    where viewModel.selectedServiceID != 5
      || search.filterServices.last != 5 {
      await Task.yield()
    }

    XCTAssertEqual(viewModel.selectedServiceID, 5)
    XCTAssertEqual(search.filterServices.last, 5)
  }

  private func makeViewModel(
    search: SearchServiceStub,
    history: SearchHistoryStub,
    selection: LiveServiceSelection? = nil
  ) -> LiveSearchViewModel {
    LiveSearchViewModel(
      searchService: search,
      historyService: history,
      serviceSelection: selection ?? makeSelection()
    )
  }

  private func makeSelection() -> LiveServiceSelection {
    let selection = LiveServiceSelection(
      settingsService: SearchSettingsStub(),
      defaults: UserDefaults(
        suiteName: "LiveSearchViewModelTests.\(UUID().uuidString)"
      )!
    )
    selection.configure(supportedServiceIDs: [0, 5])
    return selection
  }

  private static let channel = LiveChannelResult(
    id: "channel",
    name: "Blender",
    url: "https://youtube.test/channel",
    thumbnailURL: "",
    description: "Official",
    subscriberCount: 1_200,
    streamCount: 50,
    isVerified: true
  )

  private static let playlist = LivePlaylistResult(
    id: "playlist",
    title: "Open Movies",
    url: "https://youtube.test/playlist",
    thumbnailURL: "",
    uploaderName: "Blender",
    streamCount: 12,
    playlistType: "normal"
  )
}

private final class SearchSettingsStub: LiveSettingsServiceProtocol {
  private var value = LiveSettings()

  func settings() async throws -> LiveSettings {
    value
  }

  func update(_ settings: LiveSettings) async throws -> LiveSettings {
    value = settings
    return value
  }
}

private final class SearchServiceStub: LiveSearchServiceProtocol {
  struct Call {
    let serviceID: Int
    let nextPage: String?
  }

  private let lock = NSLock()
  private var pages: [LiveSearchPage]
  private var recordedCalls: [Call] = []
  private var recordedFilterServices: [Int] = []

  init(pages: [LiveSearchPage]) {
    self.pages = pages
  }

  var calls: [Call] {
    lock.withLock { recordedCalls }
  }

  var filterServices: [Int] {
    lock.withLock { recordedFilterServices }
  }

  func filters(serviceID: Int) async throws -> LiveSearchFilters {
    lock.withLock {
      recordedFilterServices.append(serviceID)
    }
    return LiveSearchFilters(
      contentFilters: [
        LiveSearchFilterOption(value: "|0|all", label: "all"),
        LiveSearchFilterOption(value: "|1|videos", label: "videos"),
      ],
      sortFilters: []
    )
  }

  func suggestions(
    query: String,
    serviceID: Int
  ) async throws -> [String] {
    ["\(query) suggestion"]
  }

  func trending(serviceID: Int) async throws -> [LiveVideoItem] {
    []
  }

  func search(
    query: String,
    serviceID: Int,
    nextPage: String?,
    contentFilter: String?,
    sortFilter: String?
  ) async throws -> LiveSearchPage {
    try lock.withLock {
      recordedCalls.append(
        Call(serviceID: serviceID, nextPage: nextPage)
      )
      guard !pages.isEmpty else {
        throw SearchViewModelTestError.unavailable
      }
      return pages.removeFirst()
    }
  }
}

private final class SearchHistoryStub:
  LiveSearchHistoryServiceProtocol {
  private let lock = NSLock()
  private var items: [LiveSearchHistoryItem]
  private var terms: [String] = []
  private let addDelay: Duration?

  init(
    items: [LiveSearchHistoryItem],
    addDelay: Duration? = nil
  ) {
    self.items = items
    self.addDelay = addDelay
  }

  var addedTerms: [String] {
    lock.withLock { terms }
  }

  func history(
    page: Int,
    limit: Int
  ) async throws -> [LiveSearchHistoryItem] {
    lock.withLock { items }
  }

  func add(term: String) async throws -> LiveSearchHistoryItem {
    if let addDelay {
      try await Task.sleep(for: addDelay)
    }
    return lock.withLock {
      terms.append(term)
      let item = LiveSearchHistoryItem(
        id: term,
        term: term,
        searchedAt: 2
      )
      items.insert(item, at: 0)
      return item
    }
  }

  func clear() async throws {
    lock.withLock {
      items = []
    }
  }
}

private enum SearchViewModelTestError: Error {
  case unavailable
}
