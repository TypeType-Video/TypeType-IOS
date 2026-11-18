import XCTest
@testable import TypeTypeIOS

final class LiveProviderLinkTests: XCTestCase {
  func testNicoNicoMylistsAndSeriesOpenAsPlaylists() throws {
    for (link, expected) in [
      ("https://www.nicovideo.jp/user/123/mylist/456", "https://www.nicovideo.jp/mylist/456"),
      ("https://www.nicovideo.jp/series/789", "https://www.nicovideo.jp/series/789"),
      ("https://www.nicovideo.jp/mylist/42", "https://www.nicovideo.jp/mylist/42"),
    ] {
      guard case let .playlist(playlist) = try destination(link) else { return XCTFail("Expected a playlist for \(link)") }
      XCTAssertEqual(playlist.url, expected)
    }
    guard case .channel = try destination("https://www.nicovideo.jp/user/123") else { return XCTFail("Expected the user page") }
  }

  func testLivesOpenOnTheWatchPage() throws {
    guard case .video = try destination("https://live.nicovideo.jp/watch/lv345678912") else { return XCTFail("NicoNico live") }
    guard case .video = try destination("https://live.bilibili.com/21452505") else { return XCTFail("BiliBili live") }
    XCTAssertNil(try destination("https://live.bilibili.com/p/eden/area-tags"))
  }

  func testALiveThatHasNotStartedSaysSo() {
    XCTAssertEqual(LiveUserError.classify(code: "live_not_started", status: 409), .liveNotStarted)
  }

  private func destination(_ text: String) throws -> LiveMediaLinkDestination? {
    LiveMediaLinkResolver.destination(for: try XCTUnwrap(URL(string: text)))
  }
}
