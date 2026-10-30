import XCTest
@testable import TypeTypeIOS

final class LiveCommentModelsTests: XCTestCase {
  private func comment(publishedAt: Int64?, text: String) -> LiveCommentItem {
    LiveCommentItem(
      id: "c1",
      text: text,
      author: "Someone",
      authorURL: "",
      authorAvatarURL: "",
      likeCount: 0,
      textualLikeCount: "0",
      publishedTime: "emahoreni angu-5 edlule",
      publishedAt: publishedAt,
      isHeartedByUploader: false,
      isPinned: false,
      uploaderVerified: false,
      replyCount: 0,
      repliesPage: nil
    )
  }

  func testPublishedDisplayDerivesFromEpochNotUpstreamText() {
    let item = comment(publishedAt: 1_609_459_200_000, text: "hi")
    XCTAssertFalse(item.publishedDisplay.contains("edlule"))
    XCTAssertFalse(item.publishedDisplay.isEmpty)
  }

  func testPublishedDisplayFallsBackToTextWithoutTimestamp() {
    XCTAssertEqual(
      comment(publishedAt: nil, text: "hi").publishedDisplay,
      "emahoreni angu-5 edlule"
    )
    XCTAssertEqual(
      comment(publishedAt: -1, text: "hi").publishedDisplay,
      "emahoreni angu-5 edlule"
    )
  }

  func testDisplayTextConvertsBreaksAndEntities() {
    let item = comment(
      publishedAt: nil,
      text: "A<br>B<br/><br />C &quot;q&quot; &amp; more"
    )
    XCTAssertEqual(item.displayText, "A\nB\n\nC \"q\" & more")
    XCTAssertFalse(item.displayText.contains("<br>"))
    XCTAssertFalse(item.displayText.contains("&quot;"))
  }
}
