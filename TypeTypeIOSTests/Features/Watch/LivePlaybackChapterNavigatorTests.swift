import XCTest
@testable import TypeTypeIOS

final class LivePlaybackChapterNavigatorTests: XCTestCase {
  private let chapters = [
    LivePlaybackChapter(
      title: "Intro",
      startTimeSeconds: 30,
      channelName: nil,
      url: nil,
      previewURL: nil
    ),
    LivePlaybackChapter(
      title: "Main",
      startTimeSeconds: 90,
      channelName: nil,
      url: nil,
      previewURL: nil
    ),
  ]

  func testCurrentChapterIsTheLastChapterAtOrBeforePosition() {
    XCTAssertNil(
      LivePlaybackChapterNavigator.currentIndex(in: chapters, at: 29)
    )
    XCTAssertEqual(
      LivePlaybackChapterNavigator.currentIndex(in: chapters, at: 30),
      0
    )
    XCTAssertEqual(
      LivePlaybackChapterNavigator.currentIndex(in: chapters, at: 89.9),
      0
    )
    XCTAssertEqual(
      LivePlaybackChapterNavigator.currentIndex(in: chapters, at: 90),
      1
    )
  }

  func testEmptyChaptersHaveNoCurrentIndex() {
    XCTAssertNil(
      LivePlaybackChapterNavigator.currentIndex(in: [], at: 30)
    )
  }

  func testSeekTargetAndTimestampFormatting() {
    let chapter = LivePlaybackChapter(
      title: "Deep",
      startTimeSeconds: 3725,
      channelName: nil,
      url: nil,
      previewURL: nil
    )

    XCTAssertEqual(
      LivePlaybackChapterNavigator.seekTarget(for: chapter),
      3725
    )
    XCTAssertEqual(
      LivePlaybackChapterNavigator.timeText(for: chapter),
      "1:02:05"
    )
  }
}
