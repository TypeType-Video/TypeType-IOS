import XCTest
@testable import TypeTypeIOS

final class LiveShareURLBuilderTests: XCTestCase {
  func testBuildsPublicInstanceWatchURL() throws {
    let source = "https://www.youtube.com/watch?v=abc&list=def"
    let url = try XCTUnwrap(
      LiveShareURLBuilder.video(
        serverURL: URL(string: "https://watch.typetype.video/api/"),
        sourceURL: source
      )
    )
    let components = try XCTUnwrap(
      URLComponents(url: url, resolvingAgainstBaseURL: false)
    )

    XCTAssertEqual(components.path, "/watch")
    XCTAssertEqual(
      components.queryItems?.first(where: { $0.name == "v" })?.value,
      source
    )
  }

  func testFallsBackToSourceWithoutInstance() throws {
    let source = "https://www.nicovideo.jp/watch/sm9"

    XCTAssertEqual(
      LiveShareURLBuilder.video(
        serverURL: nil,
        sourceURL: source
      )?.absoluteString,
      source
    )
  }
}
