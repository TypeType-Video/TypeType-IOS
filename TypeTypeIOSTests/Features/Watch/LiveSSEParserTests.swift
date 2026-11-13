import XCTest
@testable import TypeTypeIOS

final class LiveSSEParserTests: XCTestCase {
  private func parse(_ text: String) -> [LiveSSEEvent] {
    var parser = LiveSSEParser()
    var events = parser.feed(Array(text.utf8))
    if let last = parser.finish() { events.append(last) }
    return events
  }

  // The bytes the server writes for a connected stream, one message and a keep-alive (writeLiveChat).
  func testReadsTheServersStream() {
    let stream = ": connected\n\nevent: message\ndata: {\"id\":\"chat-1\",\"text\":\"Hello\",\"receivedAtMs\":1720000000000}\n\n: keep-alive\n\n"
    XCTAssertEqual(
      parse(stream),
      [LiveSSEEvent(name: "message", data: "{\"id\":\"chat-1\",\"text\":\"Hello\",\"receivedAtMs\":1720000000000}")]
    )
  }

  func testAnEventIsWholeWhateverTheChunkSizes() {
    let stream = Array("event: message\ndata: {\"text\":\"héllo 🎉\"}\n\nevent: ended\ndata: {}\n\n".utf8)
    for size in [1, 2, 3, 7, stream.count] {
      var parser = LiveSSEParser()
      var events: [LiveSSEEvent] = []
      var index = 0
      while index < stream.count {
        events += parser.feed(stream[index..<min(index + size, stream.count)])
        index += size
      }
      XCTAssertEqual(events.map(\.name), ["message", "ended"], "chunks of \(size)")
      XCTAssertEqual(events.first?.data, "{\"text\":\"héllo 🎉\"}", "chunks of \(size)")
    }
  }

  func testCarriageReturnLineFeedEndsLinesToo() {
    XCTAssertEqual(parse("event: message\r\ndata: a\r\n\r\n"), [LiveSSEEvent(name: "message", data: "a")])
  }

  func testSeveralDataLinesJoinWithANewline() {
    XCTAssertEqual(parse("data: one\ndata: two\n\n"), [LiveSSEEvent(name: "message", data: "one\ntwo")])
  }

  func testOnlyOneSpaceAfterTheColonIsDropped() {
    XCTAssertEqual(parse("data:  two spaces\n\n").first?.data, " two spaces")
    XCTAssertEqual(parse("data:none\n\n").first?.data, "none")
  }

  func testTheEventNameDoesNotLeakIntoTheNextEvent() {
    let events = parse("event: ended\ndata: 1\n\ndata: 2\n\n")
    XCTAssertEqual(events.map(\.name), ["ended", "message"])
  }

  func testCommentsUnknownFieldsAndEmptyEventsAreIgnored() {
    XCTAssertEqual(parse(": hi\nid: 7\nretry: 100\n\n\n\n"), [])
  }

  func testAnEventWithoutItsBlankLineIsDeliveredAtTheEnd() {
    XCTAssertEqual(parse("event: message\ndata: tail"), [LiveSSEEvent(name: "message", data: "tail")])
  }

  func testNothingPendingGivesNothingAtTheEnd() {
    var parser = LiveSSEParser()
    XCTAssertTrue(parser.feed(Array("data: a\n\n".utf8)).count == 1)
    XCTAssertNil(parser.finish())
  }
}
