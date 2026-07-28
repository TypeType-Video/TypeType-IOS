import XCTest
@testable import TypeTypeIOS

@MainActor
final class LivePlaybackTimelineTests: XCTestCase {
  func testIndefiniteLiveTimelineAdvancesBeyondItsOffset() {
    XCTAssertEqual(
      LivePlayerController.timelinePosition(
        playbackSeconds: 15,
        offset: 885_107,
        duration: 0
      ),
      885_122
    )
  }

  func testFiniteTimelineRemainsBoundedByDuration() {
    XCTAssertEqual(
      LivePlayerController.timelinePosition(
        playbackSeconds: 30,
        offset: 590,
        duration: 600
      ),
      600
    )
  }
}
