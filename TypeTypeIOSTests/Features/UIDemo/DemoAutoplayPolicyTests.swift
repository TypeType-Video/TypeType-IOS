import XCTest
@testable import TypeTypeIOS

final class DemoAutoplayPolicyTests: XCTestCase {
  func testDisabledAutoplayNeverAdvances() {
    XCTAssertEqual(
      DemoAutoplayPolicy.presentation(
        autoplay: false,
        source: .playlist,
        skipsPlaylistScreen: true,
        countdownSeconds: 0
      ),
      .none
    )
  }

  func testPlaylistCanSkipCountdown() {
    XCTAssertEqual(
      DemoAutoplayPolicy.presentation(
        autoplay: true,
        source: .playlist,
        skipsPlaylistScreen: true,
        countdownSeconds: 10
      ),
      .immediate
    )
  }

  func testRecommendationKeepsCountdown() {
    XCTAssertEqual(
      DemoAutoplayPolicy.presentation(
        autoplay: true,
        source: .recommendation,
        skipsPlaylistScreen: true,
        countdownSeconds: 10
      ),
      .countdown
    )
  }

  func testZeroCountdownAlwaysAdvancesImmediately() {
    XCTAssertEqual(
      DemoAutoplayPolicy.presentation(
        autoplay: true,
        source: .recommendation,
        skipsPlaylistScreen: false,
        countdownSeconds: 0
      ),
      .immediate
    )
  }
}
