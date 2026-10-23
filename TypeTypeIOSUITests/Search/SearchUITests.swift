import XCTest

final class SearchUITests: XCTestCase {
  func testSearchFindsVideosChannelsAndPlaylistsLocally() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-search"]
    app.launch()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.search.screen"]
        .waitForExistence(timeout: 5)
    )

    let search = app.searchFields["Search videos, channels..."]
    XCTAssertTrue(search.waitForExistence(timeout: 3))
    search.tap()
    search.typeText("video")

    // Channel and playlist rows sit below the fold in a lazy stack: they
    // are not in the accessibility tree until scrolled into view. Match by
    // identifier prefix instead of catalog ids so catalog rewrites do not
    // break the contract being tested: search finds channels and playlists.
    let channelRow = app.descendants(matching: .any).matching(
      NSPredicate(format: "identifier BEGINSWITH 'demo.search.channel.'")
    ).firstMatch
    let playlistRow = app.descendants(matching: .any).matching(
      NSPredicate(format: "identifier BEGINSWITH 'demo.search.playlist.'")
    ).firstMatch
    for _ in 0..<4 where !(channelRow.exists && playlistRow.exists) {
      app.swipeUp()
    }
    XCTAssertTrue(channelRow.waitForExistence(timeout: 3))
    XCTAssertTrue(playlistRow.waitForExistence(timeout: 3))
    XCTAssertTrue(
      app.buttons["demo.home.video.pipepipe-sabr"]
        .waitForExistence(timeout: 3)
    )

    app.buttons["demo.search.scope.videos"].tap()
    XCTAssertFalse(
      app.descendants(matching: .any)["demo.search.channel.typetype"].exists
    )
    XCTAssertTrue(app.buttons["demo.home.video.pipepipe-sabr"].exists)
  }

  func testSearchSuggestsCorrectedQuery() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-search"]
    app.launch()

    let search = app.searchFields["Search videos, channels..."]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText("sbar")

    let suggestion = app.buttons["demo.search.suggestion"]
    XCTAssertTrue(suggestion.waitForExistence(timeout: 3))
    suggestion.tap()
    XCTAssertTrue(
      app.buttons["demo.home.video.sabr-explained"]
        .waitForExistence(timeout: 3)
    )
  }

  func testMusicPlaylistFilterReturnsPlaylistResults() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-search"]
    app.launch()

    let search = app.searchFields["Search videos, channels..."]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText("Open")

    let filter = app.buttons["All content"]
    XCTAssertTrue(filter.waitForExistence(timeout: 3))
    filter.tap()
    app.buttons["Music playlists"].tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.search.playlist.open-audio"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertFalse(app.buttons["demo.home.video.open-source-weekly"].exists)
  }
}
