import XCTest

final class FunctionalFlowsUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  func testNotificationsOpenAndMarkReadLocally() {
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    app.buttons["demo.home.notifications"].tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.notifications.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      app.staticTexts["Blender Open Movies published a video"].exists
    )
    app.buttons["Notification actions"].tap()
    let markAllRead = app.buttons["Mark all read"]
    XCTAssertTrue(markAllRead.waitForExistence(timeout: 2))
    markAllRead.tap()
    app.buttons["Notification actions"].tap()
    XCTAssertFalse(app.buttons["Mark all read"].isEnabled)
  }

  func testEveryMockVideoCanOpenTheWatchScreen() {
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    let card = app.buttons["demo.home.video.native-ios"]
    XCTAssertTrue(card.waitForExistence(timeout: 3))
    card.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.screen"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(
      app.staticTexts["A truly native TypeType for iPhone and iPad"].exists
    )
  }

  func testPlaylistCardsOpenFunctionalDetails() {
    app.launchArguments = ["--typetype-demo-playlists"]
    app.launch()

    let card = app.buttons["demo.playlists.card.favorites"]
    XCTAssertTrue(card.waitForExistence(timeout: 3))
    card.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.playlist-detail.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.buttons["Play all"].exists)
    XCTAssertTrue(app.buttons["demo.playlist.video.big-buck-bunny"].exists)
    let playlist = XCTAttachment(screenshot: app.screenshot())
    playlist.name = "Compact mobile playlist rows"
    playlist.lifetime = .keepAlways
    add(playlist)
  }

  func testMoreDestinationsAreInteractive() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.staticTexts["Downloads"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.downloads.screen"]
        .waitForExistence(timeout: 3)
    )

    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.staticTexts["Import"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.import.screen"]
        .waitForExistence(timeout: 3)
    )
  }

  func testFavoriteStateIsSharedWithTheLibrary() {
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    let card = app.buttons["demo.home.video.native-ios"]
    XCTAssertTrue(card.waitForExistence(timeout: 3))
    card.tap()

    let favorite = app.buttons["Favorite"]
    XCTAssertTrue(favorite.waitForExistence(timeout: 5))
    favorite.tap()

    app.navigationBars["Watch"].buttons.element(boundBy: 0).tap()
    app.tabBars.buttons["Playlists"].tap()
    app.buttons["demo.playlists.card.favorites"].tap()

    XCTAssertTrue(
      app.buttons["demo.playlist.video.native-ios"]
        .waitForExistence(timeout: 3)
    )
  }

  func testPlaybackCollapsesIntoUsableMiniPlayer() {
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    app.buttons["demo.home.video.native-ios"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.screen"]
        .waitForExistence(timeout: 5)
    )
    let initialStatus = app.descendants(matching: .any)["demo.player.status"]
    let playing = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS %@", "Playing"),
      object: initialStatus
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [playing], timeout: 8),
      .completed
    )
    app.navigationBars["Watch"].buttons.element(boundBy: 0).tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.miniplayer"]
        .waitForExistence(timeout: 3)
    )
    let playback = app.buttons["demo.miniplayer.playback"]
    XCTAssertTrue(playback.exists)
    playback.tap()
    let open = app.buttons["demo.miniplayer.open"]
    XCTAssertTrue(open.exists)
    open.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.player.surface"]
        .waitForExistence(timeout: 3)
    )
    let status = app.descendants(matching: .any)["demo.player.status"]
    XCTAssertTrue(status.waitForExistence(timeout: 3))
    XCTAssertTrue(status.label.contains("Paused"))
    XCTAssertTrue(app.buttons["Minimize player"].exists)

    let resumed = XCTAttachment(screenshot: app.screenshot())
    resumed.name = "Player resumed from mini player"
    resumed.lifetime = .keepAlways
    add(resumed)
  }

  func testVideoCardMenuOpensFunctionalPlaylistSaveFlow() {
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    let options = app.buttons["Video options"].firstMatch
    XCTAssertTrue(options.waitForExistence(timeout: 3))
    options.tap()
    XCTAssertTrue(app.buttons["Save to playlist"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Block video"].exists)
    XCTAssertTrue(app.buttons["Block channel"].exists)

    app.buttons["Save to playlist"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.save"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.textFields["Playlist name"].exists)
    app.swipeUp()
    XCTAssertTrue(
      app.buttons["Create and save"].waitForExistence(timeout: 2)
    )
    app.buttons["Done"].tap()
  }

  func testDiscoveryPreferenceChangesHomeAndPersists() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.staticTexts["Discovery & services"].tap()
    let recommendations = app.switches["Home recommendations"]
    XCTAssertTrue(recommendations.waitForExistence(timeout: 3))
    XCTAssertEqual(recommendations.value as? String, "1")
    recommendations.coordinate(
      withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
    ).tap()
    XCTAssertEqual(recommendations.value as? String, "0")

    app.tabBars.buttons["Home"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.home.recommendations.hidden"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.staticTexts["Continue watching"].exists)

    app.tabBars.buttons["More"].tap()
    XCTAssertTrue(
      app.switches["Home recommendations"].waitForExistence(timeout: 3)
    )
    XCTAssertEqual(
      app.switches["Home recommendations"].value as? String,
      "0"
    )
  }

  func testMockImportChangesLibraryAndHistory() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.staticTexts["Import"].tap()
    app.buttons["demo.import.source.youtube"].tap()
    let sample = app.buttons["Use sample archive"]
    XCTAssertTrue(sample.waitForExistence(timeout: 3))
    sample.tap()
    XCTAssertTrue(
      app.staticTexts["Import complete"].waitForExistence(timeout: 4)
    )
    app.buttons["Done"].tap()

    app.tabBars.buttons["Playlists"].tap()
    let imported = app.staticTexts["Imported from YouTube"]
    for _ in 0..<3 where !imported.exists {
      app.swipeUp()
    }
    XCTAssertTrue(imported.waitForExistence(timeout: 3))

    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(
      app.staticTexts["Designing a calmer TypeType experience"]
        .waitForExistence(timeout: 3)
    )
  }

  func testDiscoveryUsesRealServiceChoicesWithoutBrowserOnlySurfaces() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    XCTAssertFalse(app.staticTexts["YouTube session"].exists)
    XCTAssertFalse(app.staticTexts["Embedded player"].exists)
    app.staticTexts["Discovery & services"].tap()

    let youtube = app.buttons["demo.discovery.service.youtube"]
    let nico = app.buttons["demo.discovery.service.niconico"]
    let bili = app.buttons["demo.discovery.service.bilibili"]
    XCTAssertTrue(youtube.waitForExistence(timeout: 3))
    XCTAssertTrue(nico.exists)
    XCTAssertTrue(bili.exists)
    nico.tap()
    XCTAssertTrue(app.staticTexts["NicoNico"].exists)
  }
}
