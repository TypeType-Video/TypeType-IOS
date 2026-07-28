import XCTest
@testable import TypeTypeIOS

final class LivePlaybackQueueTests: XCTestCase {
  private var defaults: UserDefaults!
  private var suiteName = ""

  override func setUp() {
    super.setUp()
    suiteName = "LivePlaybackQueueTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
  }

  override func tearDown() {
    defaults?.removePersistentDomain(forName: suiteName)
    defaults = nil
    suiteName = ""
    super.tearDown()
  }

  func testQueueMutationsKeepCurrentIdentityAndOrder() {
    let first = video("first")
    let current = video("current")
    let third = video("third")
    let fourth = video("fourth")
    var queue = snapshot(
      videos: [first, current, third, fourth],
      currentIndex: 1
    )

    queue.moveNext(index: 3)
    XCTAssertEqual(
      queue.videos.map(\.id),
      ["first", "current", "fourth", "third"]
    )
    XCTAssertEqual(queue.current?.id, "current")

    queue.moveNext(index: 0)
    XCTAssertEqual(
      queue.videos.map(\.id),
      ["current", "first", "fourth", "third"]
    )
    XCTAssertEqual(queue.currentIndex, 0)

    queue.remove(index: 2)
    XCTAssertEqual(
      queue.videos.map(\.id),
      ["current", "first", "third"]
    )
    XCTAssertEqual(queue.current?.id, "current")
  }

  func testEnqueueAdoptsCurrentAndDeduplicates() {
    let current = video("current")
    let next = video("next")
    var queue = LivePlaybackQueueSnapshot.empty

    XCTAssertEqual(
      queue.enqueue(next, current: current, playNext: false),
      .added
    )
    XCTAssertEqual(queue.videos.map(\.id), ["current", "next"])
    XCTAssertEqual(queue.currentIndex, 0)
    XCTAssertEqual(
      queue.enqueue(next, current: current, playNext: false),
      .alreadyQueued
    )
    XCTAssertEqual(
      queue.enqueue(current, current: current, playNext: true),
      .alreadyPlaying
    )
  }

  func testRepeatAllWrapsButRepeatOneStaysControllerOwned() {
    var queue = snapshot(
      videos: [video("first"), video("second")],
      currentIndex: 1
    )

    XCTAssertNil(queue.nextIndex)
    queue.repeatMode = .all
    XCTAssertEqual(queue.nextIndex, 0)
    XCTAssertEqual(queue.next?.id, "first")
    queue.repeatMode = .one
    XCTAssertNil(queue.nextIndex)
  }

  func testStoreSeparatesServerAndAccountScopes() {
    let store = LivePlaybackQueueStore(
      defaults: defaults,
      key: "queue"
    )
    let firstScope = LivePlaybackScope(
      serverID: "server-a",
      accountID: "account-a"
    )
    let secondScope = LivePlaybackScope(
      serverID: "server-a",
      accountID: "account-b"
    )
    let first = snapshot(videos: [video("first")], currentIndex: 0)
    let second = snapshot(videos: [video("second")], currentIndex: 0)

    store.save(first, for: firstScope)
    store.save(second, for: secondScope)

    XCTAssertEqual(store.load(for: firstScope), first)
    XCTAssertEqual(store.load(for: secondScope), second)
    store.clear(firstScope)
    XCTAssertNil(store.load(for: firstScope))
    XCTAssertEqual(store.load(for: secondScope), second)
  }

  func testStoreRejectsInvalidOrDuplicateQueue() {
    let store = LivePlaybackQueueStore(
      defaults: defaults,
      key: "queue"
    )
    let scope = LivePlaybackScope(
      serverID: "server",
      accountID: "account"
    )
    let value = video("same")
    let invalid = snapshot(
      videos: [value, value],
      currentIndex: 0
    )

    store.save(invalid, for: scope)

    XCTAssertNil(store.load(for: scope))
    XCTAssertNil(defaults.data(forKey: "queue"))
  }

  private func snapshot(
    videos: [LiveVideoItem],
    currentIndex: Int
  ) -> LivePlaybackQueueSnapshot {
    LivePlaybackQueueSnapshot(
      title: "Queue",
      videos: videos,
      currentIndex: currentIndex,
      repeatMode: .off,
      updatedAt: Date(timeIntervalSince1970: 1_000)
    )
  }

  private func video(_ id: String) -> LiveVideoItem {
    LiveVideoItem(
      id: id,
      title: id.capitalized,
      url: "https://www.youtube.com/watch?v=\(id)",
      thumbnailURL: "https://example.test/\(id).jpg",
      uploaderName: "Channel",
      uploaderURL: "https://www.youtube.com/@channel",
      uploaderAvatarURL: "https://example.test/channel.jpg",
      duration: 120,
      viewCount: 10,
      uploadDate: "",
      uploaded: 0,
      streamType: "VIDEO_STREAM",
      isShortFormContent: false,
      uploaderVerified: false,
      shortDescription: nil,
      publishedAt: nil,
      isLive: false,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }
}
