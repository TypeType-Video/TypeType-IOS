import XCTest
@testable import TypeTypeIOS

final class LiveShortLinkTests: XCTestCase {
  func testOnlyStrictB23CodesAreSentToTheServer() throws {
    XCTAssertEqual(LiveShortLinkService.code(of: try XCTUnwrap(URL(string: "https://b23.tv/AbC123x"))), "AbC123x")
    XCTAssertNil(LiveShortLinkService.code(of: try XCTUnwrap(URL(string: "https://b23.tv/ab"))))
    XCTAssertNil(LiveShortLinkService.code(of: try XCTUnwrap(URL(string: "https://b23.tv/a/b/c"))))
    XCTAssertNil(LiveShortLinkService.code(of: try XCTUnwrap(URL(string: "https://www.bilibili.com/video/BV1xx"))))
  }

  func testAFailedLookupKeepsTheOriginalLink() async throws {
    let link = try XCTUnwrap(URL(string: "https://b23.tv/AbC123x"))
    let resolved = await FailingShortLinks().resolve(link)
    XCTAssertEqual(resolved, link)
  }
}

private struct FailingShortLinks: LiveShortLinkServiceProtocol {
  func expand(code: String) async throws -> URL { throw NetworkError.transport }
}
