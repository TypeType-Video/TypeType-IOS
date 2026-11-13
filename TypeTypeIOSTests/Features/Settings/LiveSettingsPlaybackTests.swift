import XCTest
@testable import TypeTypeIOS

final class LiveSettingsPlaybackTests: XCTestCase {
  func testReadsTheWebPlaybackSettings() throws {
    let settings = try decode(#"{"autoplayOnOpen": false, "hideUpcomingPlaylistVideos": true, "holdPlaybackSpeed": 3}"#)

    XCTAssertFalse(settings.startsWhenOpened)
    XCTAssertTrue(settings.hidesUpcomingPlaylistVideos)
    XCTAssertEqual(settings.holdSpeed, 3)
  }

  func testOlderServersKeepTheFormerBehaviour() throws {
    let settings = try decode("{}")

    XCTAssertNil(settings.autoplayOnOpen)
    XCTAssertTrue(settings.startsWhenOpened)
    XCTAssertFalse(settings.hidesUpcomingPlaylistVideos)
    XCTAssertEqual(settings.holdSpeed, 2)
  }

  func testAnUnlistedHoldSpeedFallsBackToTwice() throws {
    XCTAssertEqual(try decode(#"{"holdPlaybackSpeed": 7}"#).holdSpeed, 2)
    XCTAssertEqual(try decode(#"{"holdPlaybackSpeed": 1.5}"#).holdSpeed, 1.5)
  }

  private func decode(_ fields: String) throws -> LiveSettings {
    var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(LiveSettings())) as? [String: Any])
    let extra = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(fields.utf8)) as? [String: Any])
    object.merge(extra) { _, new in new }
    return try JSONDecoder().decode(LiveSettings.self, from: JSONSerialization.data(withJSONObject: object))
  }
}
