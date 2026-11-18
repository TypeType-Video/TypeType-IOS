import XCTest
@testable import TypeTypeIOS

final class LiveDanmakuJumpTests: XCTestCase {
  func testReadsTimecodesAndSkipsWallClockTimes() {
    XCTAssertEqual(LiveDanmakuJump.seconds(in: "空降 12:34"), 754)
    XCTAssertEqual(LiveDanmakuJump.seconds(in: "go to 1:02:03 now"), 3723)
    XCTAssertNil(LiveDanmakuJump.seconds(in: "北京时间17:17"))
    XCTAssertNil(LiveDanmakuJump.seconds(in: "3.27 14:43"))
    XCTAssertNil(LiveDanmakuJump.seconds(in: "12:345"))
  }

  func testOffersTheLatestRecentTimecodeAwayFromThePosition() throws {
    let comments = try [
      comment("2:00", at: 95_000),
      comment("1:41", at: 98_000),
      comment("3:00", at: 99_000),
      comment("9:00", at: 120_000),
    ]
    let jump = LiveDanmakuJump.current(in: comments, position: 100, duration: 600)
    XCTAssertEqual(jump?.seconds, 180)
    XCTAssertEqual(LiveDanmakuJump.current(in: comments, position: 100, duration: 150)?.seconds, 120)
    XCTAssertNil(LiveDanmakuJump.current(in: comments, position: 100, duration: 0))
  }

  private func comment(_ text: String, at milliseconds: Int64) throws -> LiveBulletComment {
    let json = #"{"text":"\#(text)","argbColor":0,"position":"regular","relativeFontSize":1,"durationMs":\#(milliseconds),"isLive":false}"#
    return try JSONDecoder().decode(LiveBulletComment.self, from: Data(json.utf8))
  }
}
