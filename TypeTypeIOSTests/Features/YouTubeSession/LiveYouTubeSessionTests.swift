import XCTest

@testable import TypeTypeIOS

final class LiveYouTubeSessionTests: XCTestCase {
  func testServerMessagesBecomePhasesOrErrors() {
    XCTAssertEqual(LiveYouTubeBrowserMessage(text: #"{"type":"status","phase":"awaiting_login"}"#), .phase(.awaitingLogin))
    XCTAssertEqual(LiveYouTubeBrowserMessage(text: #"{"type":"error","message":"Expired"}"#), .failure("Expired"))
    XCTAssertNil(LiveYouTubeBrowserMessage(text: #"{"type":"status","phase":"dancing"}"#))
    XCTAssertNil(LiveYouTubeBrowserMessage(text: "not json"))
  }

  func testTapSendsPointerDownThenUp() {
    let messages = LiveYouTubeBrowserInput.tap(x: 10, y: 20).messages

    XCTAssertEqual(messages.map { $0["event"] as? String }, ["down", "up"])
    XCTAssertEqual(messages.first?["type"] as? String, "pointer")
    XCTAssertEqual(messages.first?["x"] as? Int, 10)
  }

  func testTypingSendsBackspacesThenTheNewText() {
    XCTAssertEqual(
      LiveYouTubeBrowserInput.edit(from: "hello", to: "help"),
      [.key("Backspace"), .key("Backspace"), .text("p")]
    )
    XCTAssertEqual(LiveYouTubeBrowserInput.edit(from: "", to: "me"), [.text("me")])
  }

  func testTapsMapIntoTheLetterboxedFrame() {
    let point = LiveYouTubeBrowserInput.point(
      CGPoint(x: 100, y: 100),
      in: CGSize(width: 200, height: 400),
      frame: CGSize(width: 400, height: 400)
    )

    XCTAssertEqual(point?.x, 200)
    XCTAssertEqual(point?.y, 0)
  }

  func testSocketMustStayOnTheInstanceAndItsTransport() throws {
    let instance = try XCTUnwrap(URL(string: "https://watch.example.test/api"))

    XCTAssertEqual(
      LiveYouTubeSessionService.socketURL(for: "/api/youtube-session/browser/a?token=t", instance: instance)?.absoluteString,
      "wss://watch.example.test/api/youtube-session/browser/a?token=t"
    )
    XCTAssertNil(LiveYouTubeSessionService.socketURL(for: "wss://other.example.test/x", instance: instance))
    XCTAssertNil(LiveYouTubeSessionService.socketURL(for: "ws://watch.example.test/x", instance: instance))
  }
}
