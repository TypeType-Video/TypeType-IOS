import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveSettledCardPrefetchTests: XCTestCase {
  private var fetched: [String] = []

  func testPrefetchesTheTwoMostVisibleCardsOnceTheScrollRests() async throws {
    let prefetch = makePrefetch()
    prefetch.place(UUID(), video: Self.video("a"), visibleFraction: 0.6, top: 0)
    prefetch.place(UUID(), video: Self.video("b"), visibleFraction: 1, top: 300)
    prefetch.place(UUID(), video: Self.video("c"), visibleFraction: 1, top: 600)
    prefetch.place(UUID(), video: Self.video("d"), visibleFraction: 0.3, top: 900)

    try await waitUntil { fetched.count == 2 }

    XCTAssertEqual(fetched, [Self.url("b"), Self.url("c")])
  }

  func testKeepsWaitingWhileTheCardsMove() async throws {
    let prefetch = makePrefetch()
    let id = UUID()
    for step in 0..<5 {
      prefetch.place(id, video: Self.video("a"), visibleFraction: 1, top: Double(step * 40))
      try await Task.sleep(for: .milliseconds(20))
    }
    XCTAssertTrue(fetched.isEmpty)

    try await waitUntil { !fetched.isEmpty }
    XCTAssertEqual(fetched, [Self.url("a")])
  }

  func testSkipsLivesAndCardsThatLeft() async throws {
    let prefetch = makePrefetch()
    let gone = UUID()
    prefetch.place(gone, video: Self.video("a"), visibleFraction: 1, top: 0)
    prefetch.place(UUID(), video: Self.video("b", isLive: true), visibleFraction: 1, top: 300)
    prefetch.remove(gone)

    try await Task.sleep(for: .milliseconds(200))

    XCTAssertTrue(fetched.isEmpty)
  }

  private func makePrefetch() -> LiveSettledCardPrefetch {
    LiveSettledCardPrefetch(settleDelay: .milliseconds(50)) { [weak self] video in
      self?.fetched.append(video.url)
    }
  }

  private func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0..<100 where !condition() {
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTAssertTrue(condition())
  }

  private static func url(_ id: String) -> String {
    "https://www.youtube.com/watch?v=\(id)"
  }

  private static func video(_ id: String, isLive: Bool = false) -> LiveVideoItem {
    LiveVideoItem(
      id: id,
      title: id,
      url: url(id),
      thumbnailURL: "",
      uploaderName: "",
      uploaderURL: "",
      uploaderAvatarURL: "",
      duration: 60,
      viewCount: 0,
      uploadDate: "",
      uploaded: 0,
      streamType: "VIDEO_STREAM",
      isShortFormContent: false,
      uploaderVerified: false,
      shortDescription: nil,
      publishedAt: nil,
      isLive: isLive,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }
}
