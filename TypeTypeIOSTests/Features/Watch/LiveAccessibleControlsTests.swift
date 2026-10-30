import XCTest

@testable import TypeTypeIOS

@MainActor
final class LiveAccessibleControlsTests: XCTestCase {
  func testVoiceOverTurnsAccessibleControlsOn() {
    var preferences = LiveAppPreferences()
    preferences.playerAccessibleControlsEnabled = false

    XCTAssertTrue(preferences.usesAccessiblePlayerControls(voiceOver: true))
    XCTAssertFalse(preferences.usesAccessiblePlayerControls(voiceOver: false))
  }

  func testControlsNeverHideWhileAccessible() async throws {
    let controls = LiveNativeControlsState()
    controls.staysVisible = true

    controls.scheduleHide()
    controls.tap()
    try await Task.sleep(for: .milliseconds(400))

    XCTAssertTrue(controls.visible)
  }
}
