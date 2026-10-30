import XCTest

@testable import TypeTypeIOS

final class LiveDownloadTextsTests: XCTestCase {
  func testDurationReadsLikeAClock() {
    XCTAssertEqual(LiveDownloadTexts.duration(754), "12:34")
    XCTAssertEqual(LiveDownloadTexts.duration(3725), "1:02:05")
    XCTAssertNil(LiveDownloadTexts.duration(0))
    XCTAssertNil(LiveDownloadTexts.duration(nil))
  }

  func testModeIsAWordNotAServerValue() {
    XCTAssertEqual(LiveDownloadTexts.mode("video"), "Video")
    XCTAssertEqual(LiveDownloadTexts.mode("audio"), "Audio")
    XCTAssertEqual(LiveDownloadTexts.mode("thumbnail"), "Thumbnail")
  }
}
