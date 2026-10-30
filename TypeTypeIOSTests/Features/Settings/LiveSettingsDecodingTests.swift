import XCTest
@testable import TypeTypeIOS

final class LiveSettingsDecodingTests: XCTestCase {
  func testDecodeTreatsMissingSubscriptionLiveStreamFieldAsUnsupported() throws {
    var source = LiveSettings()
    source.hideShorts = true
    var object = try JSONSerialization.jsonObject(
      with: JSONEncoder().encode(source)
    ) as! [String: Any]
    object.removeValue(forKey: "hideSubscriptionLiveStreams")
    let json = try JSONSerialization.data(withJSONObject: object)

    let settings = try JSONDecoder().decode(LiveSettings.self, from: json)

    XCTAssertTrue(settings.hideShorts)
    XCTAssertNil(settings.hideSubscriptionLiveStreams)
  }

  func testDecodePreservesSubscriptionLiveStreamSupport() throws {
    var source = LiveSettings()
    source.hideSubscriptionLiveStreams = true
    let json = try JSONEncoder().encode(source)

    let settings = try JSONDecoder().decode(LiveSettings.self, from: json)

    XCTAssertEqual(settings.hideSubscriptionLiveStreams, true)
  }
}
