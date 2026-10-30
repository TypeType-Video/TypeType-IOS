import XCTest

@testable import TypeTypeIOS

final class PlayerTimelineSeekGestureTests: XCTestCase {
  func testWholeVideoSpansTheWidth() {
    var seek = PlayerTimelineSeekGesture(start: 100, duration: 600, width: 300)
    XCTAssertEqual(seek.move(deltaX: 150, downwardTravel: 0), 400)
    XCTAssertEqual(seek.move(deltaX: 1_000, downwardTravel: 0), 600)
    XCTAssertFalse(seek.isFine)
  }

  func testDraggingDownSwitchesToFineSeekingWithHysteresis() {
    var seek = PlayerTimelineSeekGesture(start: 100, duration: 600, width: 300)
    XCTAssertEqual(seek.move(deltaX: 10, downwardTravel: 50), 101, accuracy: 0.0001)
    XCTAssertTrue(seek.isFine)
    _ = seek.move(deltaX: 0, downwardTravel: 40)
    XCTAssertTrue(seek.isFine)
    _ = seek.move(deltaX: 0, downwardTravel: 30)
    XCTAssertFalse(seek.isFine)
  }

  func testStoryboardFramePicksPageAndCell() {
    let frames = LivePlaybackPreviewFrames(
      urls: ["https://example.test/0.jpg", "https://example.test/1.jpg"],
      frameWidth: 160, frameHeight: 90, totalCount: 30, durationPerFrame: 2_000,
      framesPerPageX: 5, framesPerPageY: 5
    )
    let frame = frames.frame(at: 57)
    XCTAssertEqual(frame?.url.absoluteString, "https://example.test/1.jpg")
    XCTAssertEqual(frame?.column, 3)
    XCTAssertEqual(frame?.row, 0)
    XCTAssertEqual(frames.frame(at: 10_000)?.column, 4)
  }
}
