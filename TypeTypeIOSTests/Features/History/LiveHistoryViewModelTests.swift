import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveHistoryViewModelTests: XCTestCase {
  func testLoadDeduplicatesAndRemoveMutatesVisibleHistory() async {
    let first = history(id: "one", url: "https://video.test/one")
    let duplicate = history(id: "two", url: first.url)
    let service = HistoryStub(pages: [[first, duplicate]])
    let viewModel = LiveHistoryViewModel(service: service)

    await viewModel.reload()
    await viewModel.remove(first)

    XCTAssertEqual(viewModel.state, .loaded)
    XCTAssertTrue(viewModel.items.isEmpty)
    XCTAssertEqual(service.removedIDs, ["one"])
  }

  func testPaginationUsesCurrentCountAsOffset() async {
    let firstPage = (0..<30).map {
      history(id: "\($0)", url: "https://video.test/\($0)")
    }
    let extra = history(id: "extra", url: "https://video.test/extra")
    let service = HistoryStub(pages: [firstPage, [firstPage[0], extra]])
    let viewModel = LiveHistoryViewModel(service: service)

    await viewModel.reload()
    await viewModel.loadMore()

    XCTAssertEqual(service.offsets, [0, 30])
    XCTAssertEqual(viewModel.items.count, 31)
    XCTAssertFalse(viewModel.canLoadMore)
  }

  private func history(id: String, url: String) -> LiveHistoryItem {
    LiveHistoryItem(id: id, url: url, title: id, duration: 60)
  }
}

private final class HistoryStub: LiveHistoryServiceProtocol {
  var pages: [[LiveHistoryItem]]
  private(set) var offsets: [Int] = []
  private(set) var removedIDs: [String] = []

  init(pages: [[LiveHistoryItem]]) {
    self.pages = pages
  }

  func history(
    query: String?,
    from: Int64?,
    to: Int64?,
    limit: Int,
    offset: Int
  ) async throws -> [LiveHistoryItem] {
    offsets.append(offset)
    return pages.removeFirst()
  }

  func add(
    video: LiveVideoItem,
    progress: Int64
  ) async throws -> LiveHistoryItem {
    throw HistoryStubError.unexpectedCall
  }

  func remove(id: String) async throws {
    removedIDs.append(id)
  }

  func clear() async throws {}
}

private enum HistoryStubError: Error {
  case unexpectedCall
}
