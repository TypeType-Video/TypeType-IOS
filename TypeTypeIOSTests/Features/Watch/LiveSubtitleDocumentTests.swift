import XCTest
@testable import TypeTypeIOS

final class LiveSubtitleDocumentTests: XCTestCase {
  func testYouTubeTimedTextAsksForWebVTTInsteadOfTTML() throws {
    let source = try XCTUnwrap(URL(string: "https://www.youtube.com/api/timedtext?v=abc&lang=en&fmt=ttml&signature=x"))
    let url = LiveSubtitleSourceURL.playbackURL(for: source)
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    XCTAssertEqual(items.filter { $0.name == "fmt" }.map(\.value), ["vtt"])
    XCTAssertEqual(items.first { $0.name == "signature" }?.value, "x")
  }

  func testOtherSubtitleURLsStayUntouched() throws {
    let source = try XCTUnwrap(URL(string: "https://example.org/subs/en.ttml?fmt=ttml"))
    XCTAssertEqual(LiveSubtitleSourceURL.playbackURL(for: source), source)
  }

  func testReadsWebVTTWhateverTheAnnouncedType() {
    let data = Data("\u{FEFF}WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nHello\n".utf8)
    let cues = LiveSubtitleDocument.cues(in: data, mimeType: "application/ttml+xml")
    XCTAssertEqual(cues, [LiveSubtitleCue(start: 1, end: 2, text: "Hello")])
  }

  func testReadsTTMLWithSpansLineBreaksAndEntities() {
    let document = """
    <?xml version="1.0" encoding="utf-8" ?>
    <tt xml:lang="en" xmlns="http://www.w3.org/ns/ttml"><body><div>
    <p begin="00:00:17.375" end="00:00:19.458" style="s2">Hello, <span>Mr. Snail</span><br/>Tom &amp; Jerry</p>
    <p begin="00:00:20.000" end="00:00:20.000">Zero length</p>
    <p begin="2.5s" dur="1s">  Offset   time </p>
    </div></body></tt>
    """
    let cues = LiveSubtitleDocument.cues(in: Data(document.utf8), mimeType: "application/ttml+xml")
    XCTAssertEqual(cues, [
      LiveSubtitleCue(start: 2.5, end: 3.5, text: "Offset time"),
      LiveSubtitleCue(start: 17.375, end: 19.458, text: "Hello, Mr. Snail\nTom & Jerry")
    ])
  }

  func testReadsTTMLTickTimes() {
    let document = """
    <tt xmlns="http://www.w3.org/ns/ttml" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" ttp:tickRate="10000000">
    <body><div><p begin="10000000t" end="25000000t">Ticks</p></div></body></tt>
    """
    let cues = LiveSubtitleDocument.cues(in: Data(document.utf8), mimeType: "")
    XCTAssertEqual(cues, [LiveSubtitleCue(start: 1, end: 2.5, text: "Ticks")])
  }

  func testUnreadableDocumentGivesNoCue() {
    XCTAssertTrue(LiveSubtitleDocument.cues(in: Data("{\"body\":[]}".utf8), mimeType: "application/json").isEmpty)
  }
}
