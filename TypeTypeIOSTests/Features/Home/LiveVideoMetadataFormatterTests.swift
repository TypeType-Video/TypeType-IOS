import XCTest
@testable import TypeTypeIOS

final class LiveVideoMetadataFormatterTests: XCTestCase {
  func testUnknownViewCountShowsNothing() {
    XCTAssertEqual(LiveVideoMetadataFormatter.views(-1), "")
    XCTAssertEqual(LiveVideoMetadataFormatter.views(0), "0 views")
  }

  func testPublicationDerivesFromEpochNotUpstreamText() throws {
    let video = try LiveVideoItem.fixture(
      uploaded: 1_609_459_200_000,
      uploadDate: "emahoreni angu-3 edlule"
    )
    let text = LiveVideoMetadataFormatter.publication(video)
    XCTAssertFalse(text.contains("edlule"))
    XCTAssertFalse(text.isEmpty)
  }

  func testPublicationOmitsDateWithoutAnyTimestamp() throws {
    let video = try LiveVideoItem.fixture(
      uploaded: -1,
      uploadDate: "ezinsukwini ezingu-3 ezedlule."
    )
    XCTAssertEqual(LiveVideoMetadataFormatter.publication(video), "")
    XCTAssertEqual(LiveVideoMetadataFormatter.fullPublication(video), "")
  }
}

private extension LiveVideoItem {
  static func fixture(uploaded: Int64, uploadDate: String) throws -> LiveVideoItem {
    LiveVideoItem(
      id: "fixture",
      title: "Fixture",
      url: "https://www.youtube.com/watch?v=fixture0001",
      thumbnailURL: "",
      uploaderName: "Channel",
      uploaderURL: "",
      uploaderAvatarURL: "",
      duration: 10,
      viewCount: 0,
      uploadDate: uploadDate,
      uploaded: uploaded,
      streamType: "VIDEO_STREAM",
      isShortFormContent: false,
      uploaderVerified: false,
      isLive: false,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }
}
