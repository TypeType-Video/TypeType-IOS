import SwiftUI
import XCTest
@testable import TypeTypeIOS

final class LiveAppearancePreferenceTests: XCTestCase {
  func testModesMapToSwiftUIColorSchemes() {
    XCTAssertNil(LiveAppearanceMode.system.colorScheme)
    XCTAssertEqual(LiveAppearanceMode.light.colorScheme, .light)
    XCTAssertEqual(LiveAppearanceMode.dark.colorScheme, .dark)
  }

  func testUnknownStoredValueFallsBackToSystem() {
    XCTAssertEqual(
      LiveAppearancePreference.mode(for: "electric-blue"),
      .system
    )
    XCTAssertEqual(
      LiveAppearancePreference.mode(for: LiveAppearanceMode.dark.rawValue),
      .dark
    )
  }

  func testPreferenceUsesAStableStorageKeyAndDefault() {
    XCTAssertEqual(
      LiveAppearancePreference.storageKey,
      "typetype.appearance.mode"
    )
    XCTAssertEqual(
      LiveAppearancePreference.defaultRawValue,
      LiveAppearanceMode.system.rawValue
    )
  }
}
