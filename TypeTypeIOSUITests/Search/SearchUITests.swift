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

    // Assert each kind under its own scope: the mixed list stacks channels
    // and playlists below the fold in a lazy stack, while a scoped list
    // shows them at the top. Match by identifier prefix so catalog rewrites
    // do not break the contract being tested: search finds every kind.
    app.buttons["demo.search.scope.channels"].tap()
    let channelRow = app.descendants(matching: .any).matching(
      NSPredicate(format: "identifier BEGINSWITH 'demo.search.channel.'")
    ).firstMatch
    XCTAssertTrue(channelRow.waitForExistence(timeout: 3))

    app.buttons["demo.search.scope.playlists"].tap()
    let playlistRow = app.descendants(matching: .any).matching(
      NSPredicate(format: "identifier BEGINSWITH 'demo.search.playlist.'")
    ).firstMatch
    XCTAssertTrue(playlistRow.waitForExistence(timeout: 3))

    app.buttons["demo.search.scope.videos"].tap()
    XCTAssertFalse(
      app.descendants(matching: .any).matching(
        NSPredicate(format: "identifier BEGINSWITH 'demo.search.channel.'")
      ).firstMatch.exists
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
