import XCTest
@testable import TypeTypeIOS

final class PlayerSwipeAdjustmentRulesTests: XCTestCase {
  func testVerticalLeftDragActivatesBrightness() {
    let kind = PlayerSwipeAdjustmentRules.kind(
      startLocation: CGPoint(x: 100, y: 120),
      size: CGSize(width: 400, height: 225),
      translation: CGSize(width: 3, height: -24)
    )

    XCTAssertEqual(kind, .brightness)
  }

  func testVerticalRightDragActivatesVolume() {
    let kind = PlayerSwipeAdjustmentRules.kind(
      startLocation: CGPoint(x: 300, y: 120),
      size: CGSize(width: 400, height: 225),
      translation: CGSize(width: -2, height: 28)
    )

    XCTAssertEqual(kind, .volume)
  }

  func testHorizontalAndControlZoneDragsDoNotActivate() {
    let horizontal = PlayerSwipeAdjustmentRules.kind(
      startLocation: CGPoint(x: 300, y: 120),
      size: CGSize(width: 400, height: 225),
      translation: CGSize(width: 40, height: 20)
    )
    let controls = PlayerSwipeAdjustmentRules.kind(
      startLocation: CGPoint(x: 100, y: 205),
      size: CGSize(width: 400, height: 225),
      translation: CGSize(width: 0, height: -40)
    )

    XCTAssertNil(horizontal)
    XCTAssertNil(controls)
  }

  func testSwipeUpIncreasesAndClampsFraction() {
    XCTAssertEqual(
      PlayerSwipeAdjustmentRules.fraction(
        base: 0.4,
        translationHeight: -35,
        height: 225
      ),
      0.4 + 35 / (225 * PlayerSwipeAdjustmentRules.travelFactor),
      accuracy: 0.0001
    )
    XCTAssertEqual(
      PlayerSwipeAdjustmentRules.fraction(
        base: 0.4,
        translationHeight: -500,
        height: 225
      ),
      1,
      accuracy: 0.0001
    )
  }
}
