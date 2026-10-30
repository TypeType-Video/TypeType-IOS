import XCTest
@testable import TypeTypeIOS

final class LiveOfflineResumeStoreTests: XCTestCase {
  private var defaults: UserDefaults!
  private var store: LiveOfflineResumeStore!

  override func setUp() {
    super.setUp()
    let suite = "LiveOfflineResumeStoreTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suite)
    store = LiveOfflineResumeStore(defaults: defaults)
  }

  func testKeepsThePositionOfEachVideo() {
    store.save(42, duration: 600, for: "a")
    store.save(90, duration: 600, for: "b")

    XCTAssertEqual(store.position(for: "a"), 42)
    XCTAssertEqual(store.position(for: "b"), 90)
    XCTAssertNil(store.position(for: "c"))
  }

  func testTheStartAndTheEndForgetThePosition() {
    store.save(42, duration: 600, for: "a")
    store.save(595, duration: 600, for: "a")
    XCTAssertNil(store.position(for: "a"))

    store.save(42, duration: 600, for: "a")
    store.save(2, duration: 600, for: "a")
    XCTAssertNil(store.position(for: "a"))
  }

  func testKeepsOnlyTheMostRecentVideos() {
    for index in 0...LiveOfflineResumeStore.limit {
      store.save(30, duration: 600, for: "video-\(index)")
    }

    XCTAssertNil(store.position(for: "video-0"))
    XCTAssertEqual(store.position(for: "video-\(LiveOfflineResumeStore.limit)"), 30)
  }
}
