import XCTest
@testable import TypeTypeIOS

final class PlayerDoubleTapSeekTests: XCTestCase {
  func testDirectionSplitsSurfaceIntoBackAndForwardZones() {
    XCTAssertEqual(
      PlayerDoubleTapSeek.direction(x: 40, width: 200),
      .back
    )
    XCTAssertEqual(
      PlayerDoubleTapSeek.direction(x: 160, width: 200),
      .forward
    )
  }

  func testDirectionRejectsInvalidSurfacePoints() {
    XCTAssertNil(PlayerDoubleTapSeek.direction(x: -1, width: 200))
    XCTAssertNil(PlayerDoubleTapSeek.direction(x: 201, width: 200))
    XCTAssertNil(PlayerDoubleTapSeek.direction(x: 100, width: 0))
  }

  func testTargetSeeksTenSecondsAndStaysWithinDuration() {
    XCTAssertEqual(
      PlayerDoubleTapSeek.target(
        current: 104,
        duration: 600,
        direction: .forward
      ),
      114
    )
    XCTAssertEqual(
      PlayerDoubleTapSeek.target(
        current: 104,
        duration: 600,
        direction: .back
      ),
      94
    )
  }

  func testTargetClampsAndIgnoresForwardSeekWithoutDuration() {
    XCTAssertEqual(
      PlayerDoubleTapSeek.target(
        current: 5,
        duration: 600,
        direction: .back
      ),
      0
    )
    XCTAssertEqual(
      PlayerDoubleTapSeek.target(
        current: 595,
        duration: 600,
        direction: .forward
      ),
      600
    )
    XCTAssertNil(
      PlayerDoubleTapSeek.target(
        current: 10,
        duration: 0,
        direction: .forward
      )
    )
  }
}
