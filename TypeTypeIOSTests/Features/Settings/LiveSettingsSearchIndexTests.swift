import XCTest
@testable import TypeTypeIOS

final class LiveSettingsSearchIndexTests: XCTestCase {
  func testFindsSingleSettingsInsideSubPagesAndRanksTitleMatchesFirst() {
    let entries = LiveSettingsSearchIndex.entries(pages: [.appearance, .player, .content, .privacy])
    let speed = LiveSettingsSearchIndex.search("speed", in: entries)
    XCTAssertTrue(speed.prefix(4).contains { $0.title == "Default speed" })
    XCTAssertTrue(speed.contains { $0.title == "Danmaku speed" && $0.target == .danmaku })
    XCTAssertEqual(LiveSettingsSearchIndex.search("  HISTORY ", in: entries).first?.target, .page(.privacy))
    XCTAssertTrue(LiveSettingsSearchIndex.search("sponsor", in: entries).allSatisfy { $0.target == .sponsorBlock || $0.target == .page(.player) })
    XCTAssertTrue(LiveSettingsSearchIndex.search("", in: entries).isEmpty)
  }

  func testLeavesOutPagesTheInstanceDoesNotOffer() {
    let entries = LiveSettingsSearchIndex.entries(pages: [.appearance])
    XCTAssertTrue(LiveSettingsSearchIndex.search("speed", in: entries).isEmpty)
  }
}
