import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveWatchProgressStoreTests: XCTestCase {
  func testLoadsCardProgressOnceInABatch() async {
    let store = LiveWatchProgressStore()
    var calls: [[String]] = []
    store.loader = { urls in
      calls.append(urls)
      return ["https://www.youtube.com/watch?v=video-1": 298_000]
    }
    let first = LiveVideoItemFixture.make()
    let second = LiveVideoItemFixture.make(id: "video-2", url: "https://www.youtube.com/watch?v=video-2")

    await store.load([first, second])
    await store.load([first, second])

    XCTAssertEqual(calls.count, 1)
    XCTAssertEqual(store.fraction(forVideoID: first.canonicalID) ?? 0, 0.5, accuracy: 0.01)
    XCTAssertNil(store.fraction(forVideoID: second.canonicalID))
  }
}
