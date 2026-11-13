import XCTest
@testable import TypeTypeIOS

final class LiveChatEventDecoderTests: XCTestCase {
  private func decode(_ name: String, _ data: String) throws -> LiveChatEvent? {
    try LiveChatEventDecoder.decode(LiveSSEEvent(name: name, data: data))
  }

  func testAMessageKeepsItsAuthorAndModeratorFlag() throws {
    let event = try decode(
      "message",
      "{\"id\":\"chat-1\",\"text\":\"Hello\",\"receivedAtMs\":1720000000000,\"authorName\":\" Mika \",\"authorAvatarUrl\":null,\"moderator\":true}"
    )
    XCTAssertEqual(event, .message(LiveChatMessage(id: "chat-1", author: "Mika", text: "Hello", moderator: true)))
  }

  // A YouTube live message as the server sends it: no moderator field, an avatar address.
  func testReadsARealServerMessage() throws {
    let event = try decode(
      "message",
      "{\"id\":\"chat-1\",\"text\":\"sei sette\",\"receivedAtMs\":1793994518651,\"authorName\":\"@Viewer\",\"authorAvatarUrl\":\"https://avatar.test/viewer=s64-c-k-c0x00ffffff-no-rj\"}"
    )
    XCTAssertEqual(event, .message(LiveChatMessage(id: "chat-1", author: "@Viewer", text: "sei sette", moderator: false)))
  }

  func testTheOptionalFieldsMayBeMissing() throws {
    let event = try decode("message", "{\"id\":\"chat-2\",\"text\":\"Hi\",\"receivedAtMs\":1}")
    XCTAssertEqual(event, .message(LiveChatMessage(id: "chat-2", author: "", text: "Hi", moderator: false)))
  }

  func testAMessageWithoutTextOrWithAnUnreadablePayloadIsSkipped() throws {
    XCTAssertNil(try decode("message", "{\"id\":\"a\",\"text\":\"   \",\"receivedAtMs\":1}"))
    XCTAssertNil(try decode("message", "{\"id\":\"a\",\"receivedAtMs\":1}"))
    XCTAssertNil(try decode("message", "not json"))
    XCTAssertNil(try decode("message", "{\"id\":\"a\",\"text\":\"x\",\"moderator\":\"yes\"}"))
  }

  func testAMessageWithoutAnIdStillShows() throws {
    guard case let .message(message)? = try decode("message", "{\"text\":\"Hi\"}") else {
      return XCTFail("a message without an id should still be shown")
    }
    XCTAssertFalse(message.id.isEmpty)
  }

  func testEndedEndsTheChat() throws {
    XCTAssertEqual(try decode("ended", "{}"), .ended)
  }

  func testAnErrorEventThrowsItsMessage() {
    XCTAssertThrowsError(try decode("error", "{\"error\":\"Live chat retrieval failed\"}")) { error in
      XCTAssertEqual(error as? LiveChatStreamError, .server("Live chat retrieval failed"))
    }
    XCTAssertThrowsError(try decode("error", "plain text")) { error in
      XCTAssertEqual(error as? LiveChatStreamError, .server("plain text"))
    }
  }

  func testAnUnknownEventIsIgnored() throws {
    XCTAssertNil(try decode("ping", "{}"))
  }

  func testTextIsOneCleanLine() {
    XCTAssertEqual(LiveChatEventDecoder.clean("  two\n\nlines \u{FFFC}and\u{200B}  gaps\t"), "two lines and gaps")
    XCTAssertEqual(LiveChatEventDecoder.clean("\u{FEFF}\u{2060}"), "")
  }

  func testEmojiThatNeedTheJoinerStayWhole() {
    let family = "👨\u{200D}👩\u{200D}👧"
    XCTAssertEqual(LiveChatEventDecoder.clean("hi \(family)"), "hi \(family)")
  }
}
