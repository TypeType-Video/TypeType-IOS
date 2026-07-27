import XCTest
@testable import TypeTypeIOS

final class MediaLinkResolverTests: XCTestCase {
  func testSupportedVideoServicesResolveInsideTypeType() {
    let links = [
      DemoWatchLinkCatalog.youtube,
      DemoWatchLinkCatalog.nicoNico,
      DemoWatchLinkCatalog.biliBili,
    ]

    for link in links {
      XCTAssertNotNil(
        DemoMediaLinkResolver.internalVideo(for: link),
        "\(link.host ?? "Unknown host") should resolve internally."
      )
    }
  }

  func testUnrelatedWebsiteRemainsExternal() {
    XCTAssertNil(
      DemoMediaLinkResolver.internalVideo(
        for: DemoBigBuckBunnySource.projectURL
      )
    )
  }

  func testRichTextCreatesSeekAndWebLinks() {
    let text =
      "Compare 1:44 with https://www.youtube.com/watch?v=YE7VzlLtp-4"
    let attributed = RichTextParser.attributed(text)
    let links = attributed.runs.compactMap(\.link)

    XCTAssertEqual(links.count, 2)
    let seek = links.first { $0.scheme == "typetype" }
    XCTAssertEqual(
      seek.flatMap(RichTextParser.seekSeconds(from:)),
      104
    )
    XCTAssertTrue(
      links.contains { $0.host == "www.youtube.com" }
    )
  }

  func testHourTimestampIsConvertedToSeconds() {
    let attributed = RichTextParser.attributed("Resume at 1:02:03")
    let seek = attributed.runs.compactMap(\.link).first

    XCTAssertEqual(
      seek.flatMap(RichTextParser.seekSeconds(from:)),
      3_723
    )
  }
}
