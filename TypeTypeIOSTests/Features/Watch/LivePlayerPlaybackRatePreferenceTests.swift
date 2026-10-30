import XCTest
@testable import TypeTypeIOS

final class LivePlayerPlaybackRatePreferenceTests: XCTestCase {
  func testNormalizationStaysWithinPlayerAndSABRLimits() {
    XCTAssertEqual(
      LivePlayerController.normalizePlaybackRate(-1),
      0.25
    )
    XCTAssertEqual(
      LivePlayerController.normalizePlaybackRate(8),
      4
    )
    XCTAssertEqual(
      LivePlayerController.normalizePlaybackRate(1.5),
      1.5
    )
  }

  func testPlaybackRatePersistsAndFallsBackToNormal() throws {
    let suiteName = "LivePlayerPlaybackRatePreferenceTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    XCTAssertEqual(LivePlayerController.loadPlaybackRate(defaults: defaults), 1)

    LivePlayerController.savePlaybackRate(12, defaults: defaults)
    XCTAssertEqual(LivePlayerController.loadPlaybackRate(defaults: defaults), 4)

    LivePlayerController.savePlaybackRate(0.75, defaults: defaults)
    XCTAssertEqual(
      LivePlayerController.loadPlaybackRate(defaults: defaults),
      0.75,
      accuracy: 0.001
    )
  }
}
