import XCTest
@testable import TypeTypeIOS

final class LiveBulletCommentTests: XCTestCase {
  func testDecodesServerTimestampAndPresentationFields() throws {
    let data = Data(
      """
      {
        "comments": [{
          "text": "Hello",
          "argbColor": -16711936,
          "position": "REGULAR",
          "relativeFontSize": 1.25,
          "durationMs": 4321,
          "isLive": false
        }],
        "nextpage": "cursor"
      }
      """.utf8
    )

    let page = try JSONDecoder().decode(
      LiveBulletCommentsPage.self,
      from: data
    )

    XCTAssertEqual(page.nextpage, "cursor")
    XCTAssertEqual(page.comments.count, 1)
    XCTAssertEqual(page.comments[0].text, "Hello")
    XCTAssertEqual(page.comments[0].position, "REGULAR")
    XCTAssertEqual(page.comments[0].durationMilliseconds, 4_321)
    XCTAssertEqual(page.comments[0].relativeFontSize, 1.25)
    XCTAssertFalse(page.comments[0].isLive)
  }
}
