import XCTest
@testable import TypeTypeIOS

final class PlayerFullscreenExitRulesTests: XCTestCase {
  private let size = CGSize(width: 800, height: 400)

  func testBeginsOnADownwardSwipeFromTheCentreBand() {
    XCTAssertTrue(PlayerFullscreenExitRules.canBegin(
      startLocation: CGPoint(x: 400, y: 200), size: size, translation: CGSize(width: 3, height: 12)
    ))
  }

  func testLeavesTheSidesToVolumeAndBrightness() {
    for x: CGFloat in [100, 260, 540, 700] {
      XCTAssertFalse(PlayerFullscreenExitRules.canBegin(
        startLocation: CGPoint(x: x, y: 200), size: size, translation: CGSize(width: 0, height: 12)
      ))
      let kind = PlayerSwipeAdjustmentRules.kind(
        startLocation: CGPoint(x: x, y: 200), size: size, translation: CGSize(width: 0, height: 12)
      )
      XCTAssertEqual(kind != nil, x < size.width / 3 || x > size.width * 2 / 3)
    }
  }

  func testNeverSharesATouchWithSeekingOrSwipesUp() {
    let centre = CGPoint(x: 400, y: 200)
    XCTAssertFalse(PlayerFullscreenExitRules.canBegin(
      startLocation: centre, size: size, translation: CGSize(width: 14, height: 10)
    ))
    XCTAssertFalse(PlayerFullscreenExitRules.canBegin(
      startLocation: centre, size: size, translation: CGSize(width: 0, height: -12)
    ))
  }

  func testIgnoresTouchesNearTheTopAndBottomEdges() {
    for y: CGFloat in [20, 47, 353, 390] {
      XCTAssertFalse(PlayerFullscreenExitRules.canBegin(
        startLocation: CGPoint(x: 400, y: y), size: size, translation: CGSize(width: 0, height: 12)
      ))
    }
  }

  func testCompletesAfterSixtyFourPoints() {
    XCTAssertFalse(PlayerFullscreenExitRules.completes(translationHeight: 63))
    XCTAssertTrue(PlayerFullscreenExitRules.completes(translationHeight: 64))
  }
}
