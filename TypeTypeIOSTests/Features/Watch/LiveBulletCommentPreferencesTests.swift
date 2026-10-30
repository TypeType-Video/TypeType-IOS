import XCTest

@testable import TypeTypeIOS

@MainActor
final class LiveBulletCommentPreferencesTests: XCTestCase {
  func testPlayerChoicesMoveIntoTheSettingsOnce() throws {
    let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
    defaults.set(false, forKey: "typetype.player.danmaku.enabled")
    defaults.set(1.5, forKey: "typetype.player.danmaku.speed")
    let store = LiveAppPreferencesStore(defaults: defaults)

    LivePlayerController.moveLegacyBulletCommentChoices(into: store, from: defaults)

    XCTAssertFalse(store.preferences.danmakuEnabled)
    XCTAssertEqual(store.preferences.danmakuSpeed, 1.5)
    XCTAssertEqual(store.preferences.danmakuSize, 1.0)
    XCTAssertNil(defaults.object(forKey: "typetype.player.danmaku.speed"))
  }

  func testNothingChangesWithoutOldChoices() throws {
    let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
    let store = LiveAppPreferencesStore(defaults: defaults)

    LivePlayerController.moveLegacyBulletCommentChoices(into: store, from: defaults)

    XCTAssertEqual(store.preferences, LiveAppPreferences())
  }
}
