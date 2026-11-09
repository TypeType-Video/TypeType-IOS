import XCTest
@testable import TypeTypeIOS

final class LiveSearchLinkTests: XCTestCase {
  func testProviderVideoLinksOpenTheVideo() {
    let links = [
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "https://youtu.be/dQw4w9WgXcQ",
      "https://www.youtube.com/shorts/dQw4w9WgXcQ",
      "https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=42",
      "  https://www.bilibili.com/video/BV1GJ411x7h7  ",
      "https://www.nicovideo.jp/watch/sm9",
      "https://nico.ms/sm9",
    ]
    for link in links {
      guard case .video = LiveSearchLink.destination(for: link, serverURL: nil) else {
        return XCTFail("\(link) should open a video")
      }
    }
  }

  func testLinksWithoutSchemeAreRecognised() {
    for link in ["youtu.be/dQw4w9WgXcQ", "www.youtube.com/watch?v=dQw4w9WgXcQ"] {
      guard case .video = LiveSearchLink.destination(for: link, serverURL: nil) else {
        return XCTFail("\(link) should open a video")
      }
    }
  }

  func testChannelAndPlaylistLinksOpenTheirPages() {
    guard case .channel = LiveSearchLink.destination(for: "https://www.youtube.com/@mkbhd", serverURL: nil) else {
      return XCTFail("channel link should open the channel")
    }
    guard case .playlist = LiveSearchLink.destination(
      for: "https://www.youtube.com/playlist?list=PL590L5WQmH8fJ54F369BLDSqIwcs-TCfs",
      serverURL: nil
    ) else {
      return XCTFail("playlist link should open the playlist")
    }
  }

  func testTypeTypeLinksFromAnyInstanceOpenTheVideo() {
    let server = URL(string: "https://own.example")
    for link in [
      "https://watch.typetype.video/watch?v=NWANo9BRz6Y",
      "watch.typetype.video/watch?v=NWANo9BRz6Y",
      "https://own.example/watch?v=NWANo9BRz6Y",
    ] {
      for serverURL in [server, nil] {
        guard case .video = LiveSearchLink.destination(for: link, serverURL: serverURL) else {
          return XCTFail("\(link) should open a video")
        }
      }
    }
  }

  func testTextAndOtherLinksStaySearches() {
    let inputs = ["programming", "dQw4w9WgXcQ", "never gonna give you up", "node.js", "https://example.com/watch?v=1", "sm9"]
    for input in inputs {
      XCTAssertNil(LiveSearchLink.destination(for: input, serverURL: nil), "\(input) should be searched")
    }
  }
}
