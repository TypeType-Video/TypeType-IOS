import SwiftUI
import XCTest

@testable import TypeTypeIOS

final class ThemePaletteContrastTests: XCTestCase {
  func testMonochromeAccentGetsDarkTextInDarkMode() {
    XCTAssertEqual(ThemePalette.readableText(on: LiveAccentColor.monochrome.color, isDark: true), .black)
    XCTAssertEqual(ThemePalette.readableText(on: LiveAccentColor.monochrome.color, isDark: false), .white)
  }

  func testLightAccentGetsDarkText() {
    XCTAssertEqual(ThemePalette.readableText(on: Color(red: 1, green: 0.85, blue: 0), isDark: false), .black)
  }

  func testSaturatedAccentsKeepWhiteText() {
    XCTAssertEqual(ThemePalette.readableText(on: LiveAccentColor.red.color, isDark: true), .white)
    XCTAssertEqual(ThemePalette.readableText(on: LiveAccentColor.violet.color, isDark: false), .white)
  }
}
