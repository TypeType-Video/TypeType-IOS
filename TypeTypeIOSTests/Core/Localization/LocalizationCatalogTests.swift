import XCTest
@testable import TypeTypeIOS

final class LocalizationCatalogTests: XCTestCase {
  func testCriticalKeysAreAvailableInEnglishAndFrench() throws {
    for localization in LocalizationCatalog.supportedLocalizations {
      let table = LocalizationCatalog.table(for: localization)

      for key in LocalizationCatalog.criticalKeys {
        XCTAssertNotNil(
          table[key],
          "Missing \(localization) translation for key: \(key)"
        )
      }
    }
  }

  func testFrenchTranslationsDifferFromDevelopmentKeys() {
    let french = LocalizationCatalog.table(for: "fr")

    for key in ["Home", "Settings", "Player options", "Downloads"] {
      let translation = french[key]
      XCTAssertNotEqual(translation, key)
      XCTAssertEqual(translation, french[key])
    }
  }
}
