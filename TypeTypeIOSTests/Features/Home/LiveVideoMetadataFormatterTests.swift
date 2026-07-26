import XCTest
@testable import TypeTypeIOS

final class LiveVideoMetadataFormatterTests: XCTestCase {
  func testDurationFormatsMinutesAndHours() {
    XCTAssertEqual(
      LiveVideoMetadataFormatter.duration(596),
      "9:56"
    )
    XCTAssertEqual(
      LiveVideoMetadataFormatter.duration(3_661),
      "1:01:01"
    )
  }

  func testPublicationAcceptsMillisecondEpoch() {
    let video = LiveVideoItemFixture.make(
      publishedAt: 1_785_063_770_906
    )
    let timestamp = video.publicationDate?.timeIntervalSince1970
    XCTAssertNotNil(timestamp)
    XCTAssertEqual(
      timestamp ?? 0,
      1_785_063_770.906,
      accuracy: 0.001
    )
  }
}
