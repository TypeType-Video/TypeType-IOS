import XCTest
@testable import TypeTypeIOS

final class LiveBilibiliImageSizeTests: XCTestCase {
  func testAsksBilibiliForCardSizedCoversAndSmallAvatars() {
    XCTAssertEqual(
      resolved("http://i0.hdslb.com/bfs/archive/abc.jpg"),
      "https://i0.hdslb.com/bfs/archive/abc.jpg@672w_378h_1c.webp"
    )
    XCTAssertEqual(
      resolved("https://i1.hdslb.com/bfs/face/def.jpg"),
      "https://i1.hdslb.com/bfs/face/def.jpg@240w_240h_1c.webp"
    )
  }

  func testKeepsSizedImagesOtherPathsAndOtherHosts() {
    XCTAssertEqual(
      resolved("https://i0.hdslb.com/bfs/archive/abc.jpg@320w_180h.webp"),
      "https://i0.hdslb.com/bfs/archive/abc.jpg@320w_180h.webp"
    )
    XCTAssertEqual(
      resolved("https://i0.hdslb.com/bfs/emote/smile.png"),
      "https://i0.hdslb.com/bfs/emote/smile.png"
    )
    XCTAssertEqual(
      resolved("https://i.ytimg.com/vi/abc/hqdefault.jpg"),
      "https://i.ytimg.com/vi/abc/hqdefault.jpg"
    )
  }

  func testMovesBiliimgAndSchemeRelativeCoversToTheSizedService() {
    XCTAssertEqual(
      resolved("https://archive.biliimg.com/bfs/archive/abc.jpg"),
      "https://i0.hdslb.com/bfs/archive/abc.jpg@672w_378h_1c.webp"
    )
    XCTAssertEqual(
      resolved("//i2.hdslb.com/bfs/face/def.jpg"),
      "https://i2.hdslb.com/bfs/face/def.jpg@240w_240h_1c.webp"
    )
  }

  private func resolved(_ reference: String) -> String? {
    LiveImageURLResolver.resolve(reference)?.absoluteString
  }
}
