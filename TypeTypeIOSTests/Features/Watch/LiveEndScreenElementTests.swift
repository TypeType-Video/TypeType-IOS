import XCTest
@testable import TypeTypeIOS

final class LiveEndScreenElementTests: XCTestCase {
  func testKeepsOnlyPlacedElementsOfAKnownKind() throws {
    let elements = try decode("""
      [{"id":"a","type":"video","title":"Next","url":"https://www.youtube.com/watch?v=x","startMs":590000,"endMs":610000,"left":0.65,"top":0.13,"width":0.32,"aspectRatio":1.77},
       {"id":"b","type":"poll","url":"https://x","startMs":0,"endMs":10,"left":0.1,"top":0.1,"width":0.2,"aspectRatio":1},
       {"id":"c","type":"channel","url":"https://www.youtube.com/@x","startMs":10,"endMs":5,"left":0.1,"top":0.1,"width":0.2,"aspectRatio":1},
       {"id":"d","type":"website","url":"https://example.org","startMs":0,"endMs":10,"left":1.2,"top":0.1,"width":0.2,"aspectRatio":1}]
      """)

    XCTAssertEqual(elements.filter(\.isUsable).map(\.id), ["a"])
    XCTAssertTrue(elements[0].isVisible(at: 600))
    XCTAssertFalse(elements[0].isVisible(at: 610))
  }

  func testCardsSitInTheVideoFrameAndStayInside() throws {
    let element = try XCTUnwrap(decode("""
      [{"id":"a","type":"video","url":"u","startMs":0,"endMs":1,"left":0.8,"top":0.9,"width":0.5,"aspectRatio":1.7777777}]
      """).first)
    let frame = LiveEndScreenElement.videoFrame(in: CGSize(width: 400, height: 400), videoAspectRatio: 16 / 9)

    XCTAssertEqual(frame.minY, 87.5, accuracy: 0.01)
    let box = element.box(in: frame)
    XCTAssertEqual(box.minX, 320, accuracy: 0.01)
    XCTAssertLessThanOrEqual(box.maxX, frame.maxX + 0.01)
    XCTAssertLessThanOrEqual(box.maxY, frame.maxY + 0.01)
  }

  private func decode(_ json: String) throws -> [LiveEndScreenElement] {
    try JSONDecoder().decode([LiveEndScreenElement].self, from: Data(json.utf8))
  }
}
