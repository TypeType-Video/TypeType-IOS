import XCTest
@testable import TypeTypeIOS

final class MiniPlayerDragActionTests: XCTestCase {
  func testUpwardActivationDistanceExpands() {
    XCTAssertEqual(
      MiniPlayerDragGesture.action(
        forTranslationHeight: -MiniPlayerDragGesture.activationDistance
      ),
      .expand
    )
  }

  func testDownwardActivationDistanceCloses() {
    XCTAssertEqual(
      MiniPlayerDragGesture.action(
        forTranslationHeight: MiniPlayerDragGesture.activationDistance
      ),
      .close
    )
  }

  func testShortDragReturnsToRestState() {
    XCTAssertNil(
      MiniPlayerDragGesture.action(forTranslationHeight: -55.9)
    )
    XCTAssertNil(
      MiniPlayerDragGesture.action(forTranslationHeight: 55.9)
    )
  }
}
