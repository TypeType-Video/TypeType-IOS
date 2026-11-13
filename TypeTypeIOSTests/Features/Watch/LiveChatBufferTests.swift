import XCTest
@testable import TypeTypeIOS

final class LiveChatBufferTests: XCTestCase {
  private func message(_ id: String) -> LiveChatEvent {
    .message(LiveChatMessage(id: id, author: "a", text: "text \(id)", moderator: false))
  }

  func testStartsConnectingWithoutMessages() {
    let buffer = LiveChatBuffer()
    XCTAssertEqual(buffer.status, .connecting)
    XCTAssertTrue(buffer.messages.isEmpty)
  }

  func testKeepsTheNewestThirtyInOrder() {
    var buffer = LiveChatBuffer()
    buffer.apply((1...45).map { message("\($0)") })
    XCTAssertEqual(buffer.messages.count, 30)
    XCTAssertEqual(buffer.messages.first?.id, "16")
    XCTAssertEqual(buffer.messages.last?.id, "45")
  }

  func testAMessageSentTwiceInOneConnectionShowsOnce() {
    var buffer = LiveChatBuffer()
    buffer.apply([.connected, message("1"), message("2")])
    buffer.apply([message("2"), message("3")])
    XCTAssertEqual(buffer.messages.map(\.id), ["1", "2", "3"])
  }

  // Real server: every connection numbers its messages chat-1, chat-2, ... again.
  func testANewConnectionStartsTheListOver() {
    var buffer = LiveChatBuffer()
    buffer.apply([.connected, message("chat-1"), message("chat-2")])
    buffer.apply([.connected, message("chat-1"), message("chat-2"), message("chat-3")])
    XCTAssertEqual(buffer.messages.map(\.id), ["chat-1", "chat-2", "chat-3"])
    XCTAssertEqual(buffer.messages.count, 3, "the backlog of the new connection is not shown twice")
  }

  func testAnOldIdIsForgottenAfterManyMessages() {
    var buffer = LiveChatBuffer()
    buffer.apply((1...(LiveChatBuffer.rememberedIDs + 5)).map { message("\($0)") })
    buffer.apply([message("1")])
    XCTAssertEqual(buffer.messages.last?.id, "1")
  }

  func testTheStatusFollowsTheConnection() {
    var buffer = LiveChatBuffer()
    buffer.apply([.connected])
    XCTAssertEqual(buffer.status, .connected)
    buffer.apply([.connected])
    XCTAssertEqual(buffer.status, .connected)
    buffer.apply([.ended])
    XCTAssertEqual(buffer.status, .ended)
    buffer.apply([.connected])
    XCTAssertEqual(buffer.status, .ended, "a late connected event does not undo the end")
  }

  func testUnavailableKeepsWhatWasShown() {
    var buffer = LiveChatBuffer()
    buffer.apply([message("1"), .unavailable])
    XCTAssertEqual(buffer.status, .unavailable)
    XCTAssertEqual(buffer.messages.map(\.id), ["1"])
  }

  func testOnlyYouTubeLivesHaveAChat() {
    XCTAssertTrue(LiveChatSupport.supports(videoURL: "https://www.youtube.com/watch?v=abc"))
    XCTAssertTrue(LiveChatSupport.supports(videoURL: "https://m.youtube.com/watch?v=abc"))
    XCTAssertTrue(LiveChatSupport.supports(videoURL: "https://youtu.be/abc"))
    XCTAssertFalse(LiveChatSupport.supports(videoURL: "https://www.nicovideo.jp/watch/sm9"))
    XCTAssertFalse(LiveChatSupport.supports(videoURL: "https://www.bilibili.com/video/BV1xx411c7mD"))
    XCTAssertFalse(LiveChatSupport.supports(videoURL: "https://notyoutube.com/watch?v=abc"))
  }
}
