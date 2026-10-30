import XCTest

@testable import TypeTypeIOS

final class LiveSearchFilterLabelTests: XCTestCase {
  func testServerFilterLabelsReadLikePlainWords() {
    let relevance = LiveSearchFilterOption(value: "r", label: "sortby:sort_relevance")
    XCTAssertEqual(relevance.displayName, "Relevance")
    XCTAssertEqual(relevance.groupName, "Sort By")

    let hour = LiveSearchFilterOption(value: "h", label: "upload_date:past_hour")
    XCTAssertEqual(hour.displayName, "Past Hour")
    XCTAssertEqual(hour.groupName, "Upload Date")
  }

  func testUngroupedLabelsKeepTheirWords() {
    let videos = LiveSearchFilterOption(value: "v", label: "music_songs")
    XCTAssertEqual(videos.displayName, "Music Songs")
    XCTAssertNil(videos.groupName)
  }
}
