import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveChannelURLCanonicalizerTests: XCTestCase {
  func testCanonicalizeUpgradesSchemeAndStripsDecorations() {
    XCTAssertEqual(
      LiveChannelURLCanonicalizer.canonicalize(
        "http://www.youtube.com/channel/UC123/?ref=share#top"
      ),
      "https://www.youtube.com/channel/UC123"
    )
  }

  func testCanonicalizeKeepsHandlePaths() {
    XCTAssertEqual(
      LiveChannelURLCanonicalizer.canonicalize(
        "https://www.youtube.com/@someCreator"
      ),
      "https://www.youtube.com/@someCreator"
    )
  }

  func testCanonicalizePassesUnparsableValuesThrough() {
    XCTAssertEqual(
      LiveChannelURLCanonicalizer.canonicalize("not a url"),
      "not a url"
    )
  }

  func testIdentityComparesAcrossCasingAndDecorations() {
    XCTAssertEqual(
      LiveChannelURLCanonicalizer.identity(
        "https://www.YouTube.com/channel/UC123/"
      ),
      LiveChannelURLCanonicalizer.identity(
        "http://www.youtube.com/channel/UC123"
      )
    )
    XCTAssertNotEqual(
      LiveChannelURLCanonicalizer.identity(
        "https://www.youtube.com/channel/UC123"
      ),
      LiveChannelURLCanonicalizer.identity(
        "https://www.youtube.com/@UC123"
      )
    )
  }
}
