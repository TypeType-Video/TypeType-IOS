import XCTest
@testable import TypeTypeIOS

final class LiveVideoItemShortFormTests: XCTestCase {
  func testShortsAreRecognisedLikeOnTheWeb() {
    XCTAssertTrue(LiveVideoItemFixture.make(isShort: true).isShortForm)
    XCTAssertTrue(LiveVideoItemFixture.make(streamType: "SHORT_FORM").isShortForm)
    XCTAssertTrue(LiveVideoItemFixture.make(url: "https://www.youtube.com/shorts/abc").isShortForm)
    XCTAssertTrue(LiveVideoItemFixture.make(id: "shorts/abc", url: "https://youtube.test/v/abc").isShortForm)
    XCTAssertFalse(LiveVideoItemFixture.make().isShortForm)
    XCTAssertFalse(LiveVideoItemFixture.make(url: "https://www.youtube.com/watch?v=shortsy").isShortForm)
  }

  func testHidingShortsKeepsTheOrderOfTheRest() {
    let videos = [
      LiveVideoItemFixture.make(id: "a", url: "https://youtube.test/a"),
      LiveVideoItemFixture.make(id: "b", url: "https://youtube.test/b", isShort: true),
      LiveVideoItemFixture.make(id: "c", url: "https://youtube.test/c"),
    ]
    XCTAssertEqual(videos.hidingShorts(true).map(\.id), ["a", "c"])
    XCTAssertEqual(videos.hidingShorts(false).map(\.id), ["a", "b", "c"])
  }
}
