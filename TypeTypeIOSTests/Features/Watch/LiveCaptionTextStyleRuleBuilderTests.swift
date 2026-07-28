import CoreMedia
import XCTest
@testable import TypeTypeIOS

final class LiveCaptionTextStyleRuleBuilderTests: XCTestCase {
  func testMapsTypeTypeCaptionStylesToNativeMarkup() throws {
    let styles = LiveCaptionStyles(
      fontFamily: "mono-sans",
      fontSize: "150%",
      textColor: "#ffffff",
      textOpacity: "75%",
      textShadow: "outline",
      textBackground: "#000000",
      textBackgroundOpacity: "50%",
      displayBackground: "#ff0000",
      displayBackgroundOpacity: "25%"
    )

    let attributes = LiveCaptionTextStyleRuleBuilder.attributes(
      for: styles
    )
    XCTAssertEqual(
      attributes[string(kCMTextMarkupAttribute_RelativeFontSize)] as? Double,
      150
    )
    XCTAssertEqual(
      attributes[
        string(kCMTextMarkupAttribute_GenericFontFamilyName)
      ] as? String,
      string(kCMTextMarkupGenericFontName_MonospaceSansSerif)
    )
    XCTAssertEqual(
      attributes[
        string(kCMTextMarkupAttribute_CharacterEdgeStyle)
      ] as? String,
      string(kCMTextMarkupCharacterEdgeStyle_Uniform)
    )
    XCTAssertEqual(
      color(
        attributes[string(kCMTextMarkupAttribute_ForegroundColorARGB)]
      ),
      [0.75, 1, 1, 1]
    )
    XCTAssertEqual(
      color(
        attributes[
          string(kCMTextMarkupAttribute_CharacterBackgroundColorARGB)
        ]
      ),
      [0.5, 0, 0, 0]
    )
    XCTAssertEqual(
      color(
        attributes[string(kCMTextMarkupAttribute_BackgroundColorARGB)]
      ),
      [0.25, 1, 0, 0]
    )
  }

  func testEmptyStylesPreserveSystemAppearance() {
    XCTAssertTrue(
      LiveCaptionTextStyleRuleBuilder.attributes(
        for: LiveCaptionStyles()
      ).isEmpty
    )
    XCTAssertNil(
      LiveCaptionTextStyleRuleBuilder.rules(
        for: LiveCaptionStyles()
      )
    )
  }

  private func string(_ value: CFString) -> String {
    value as String
  }

  private func color(_ value: Any?) -> [Double]? {
    (value as? [NSNumber])?.map(\.doubleValue)
  }
}
