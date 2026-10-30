import CoreMedia
import XCTest

@testable import TypeTypeIOS

final class LiveSettingsOptionsTests: XCTestCase {
  func testCodecsOnlyListWhatTheDeviceDecodesInHardware() {
    let options = LiveCodecOptions.available { $0 == kCMVideoCodecType_VP9 }

    XCTAssertEqual(options.map(\.0), ["recommended", "vp9", "h264"])
  }

  func testAllHardwareCodecsAreListedWhenSupported() {
    let options = LiveCodecOptions.available { _ in true }

    XCTAssertEqual(options.map(\.0), ["recommended", "av1", "vp9", "h264"])
  }

  func testAStoredCodecTheDeviceCannotDecodeShowsAsAuto() {
    let options = LiveCodecOptions.available { _ in false }

    XCTAssertEqual(LiveCodecOptions.shown("av1", among: options), "recommended")
    XCTAssertEqual(LiveCodecOptions.shown("h264", among: options), "h264")
  }

  func testLanguagesStartWithAutoAndUseTheirOwnNames() {
    let options = LiveLanguageOptions.options

    XCTAssertEqual(options.first?.0, "")
    XCTAssertEqual(LiveLanguageOptions.nativeName(of: "fr"), "Français")
    XCTAssertEqual(LiveLanguageOptions.nativeName(of: "de"), "Deutsch")
    XCTAssertEqual(LiveLanguageOptions.nativeName(of: "ja"), "日本語")
  }
}
