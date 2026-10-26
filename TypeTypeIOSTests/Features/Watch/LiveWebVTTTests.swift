import XCTest
@testable import TypeTypeIOS

final class LiveWebVTTTests: XCTestCase {
  private let document = """
  WEBVTT
  Kind: captions

  1
  00:00:01.000 --> 00:00:03.500 align:start position:0%
  Hello <c>there</c>

  00:00:03.500 --> 00:00:05.000
  Tom &amp; Jerry
  second line

  01:02.000 --> 01:04.250
  Short form
  """

  func testParsesCuesTagsAndEntities() {
    let cues = LiveWebVTT.cues(in: document)
    XCTAssertEqual(cues.count, 3)
    XCTAssertEqual(cues[0], LiveSubtitleCue(start: 1, end: 3.5, text: "Hello there"))
    XCTAssertEqual(cues[1].text, "Tom & Jerry\nsecond line")
    XCTAssertEqual(cues[2].start, 62)
    XCTAssertEqual(cues[2].end, 64.25)
  }

  func testFindsTheCueShownAtATime() {
    let cues = LiveWebVTT.cues(in: document)
    XCTAssertNil(LiveWebVTT.cue(at: 0.5, in: cues))
    XCTAssertEqual(LiveWebVTT.cue(at: 2, in: cues)?.text, "Hello there")
    XCTAssertEqual(LiveWebVTT.cue(at: 3.5, in: cues)?.text, "Tom & Jerry\nsecond line")
    XCTAssertNil(LiveWebVTT.cue(at: 10, in: cues))
  }
}
