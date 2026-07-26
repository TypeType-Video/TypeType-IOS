import XCTest

final class PlayerUITests: XCTestCase {
  func testBigBuckBunnyStartsPlayingWithoutBackend() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.screen"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.player.surface"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(
      app.staticTexts["Big Buck Bunny — Blender Open Movie"].exists
    )

    let status = app.descendants(matching: .any)["demo.player.status"]
    XCTAssertTrue(status.waitForExistence(timeout: 5))
    let playing = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS %@", "Playing"),
      object: status
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [playing], timeout: 8),
      XCTWaiter.Result.completed,
      "Unexpected player status: \(status.label)"
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.actions"].exists
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.description"].exists
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.queue"].exists
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.comments"].exists
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.related"].exists
    )
  }

  func testBigBuckBunnyOpensFromHome() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    let card = app.buttons["demo.home.video.big-buck-restored"]
    XCTAssertTrue(card.waitForExistence(timeout: 5))
    card.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.screen"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(app.navigationBars["Watch"].exists)
  }

  func testPlayerOptionsAndQuickActionsAreInteractive() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let options = app.buttons["demo.player.inline-options"]
    XCTAssertTrue(options.waitForExistence(timeout: 5))
    options.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.player.options"]
        .waitForExistence(timeout: 3)
    )
    let audioBoost = app.steppers["demo.player.audio-boost"]
    XCTAssertTrue(audioBoost.waitForExistence(timeout: 2))
    let increment = app.buttons["demo.player.audio-boost-Increment"]
    XCTAssertTrue(increment.waitForExistence(timeout: 2))
    increment.tap()
    XCTAssertTrue(
      app.steppers.matching(
        NSPredicate(format: "label CONTAINS %@", "125%")
      ).firstMatch.waitForExistence(timeout: 2)
    )
    let sponsorBlock = app.switches["demo.player.options.sponsorblock"]
    if !sponsorBlock.exists {
      app.swipeUp()
    }
    XCTAssertTrue(sponsorBlock.waitForExistence(timeout: 2))
    XCTAssertTrue(
      app.switches["demo.player.options.dearrow"]
        .waitForExistence(timeout: 2)
    )
    app.buttons["Done"].tap()

    let status = app.descendants(matching: .any)["demo.player.status"]
    let boostedPlayback = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS %@", "Playing"),
      object: status
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [boostedPlayback], timeout: 8),
      .completed
    )

    let actions = app.descendants(matching: .any)["demo.watch.actions"]
    XCTAssertTrue(actions.waitForExistence(timeout: 3))
    let wasFavorite = app.buttons["Favorited"].exists
    let favorite = wasFavorite
      ? app.buttons["Favorited"]
      : app.buttons["Favorite"]
    XCTAssertTrue(favorite.waitForExistence(timeout: 3))
    favorite.tap()
    XCTAssertTrue(
      app.buttons[wasFavorite ? "Favorite" : "Favorited"]
        .waitForExistence(timeout: 2)
    )
  }

  func testPlayerOptionsShortcutIsPortraitOnly() {
    let device = XCUIDevice.shared
    device.orientation = .portrait
    defer { device.orientation = .portrait }

    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let shortcut = app.buttons["demo.player.inline-options"]
    XCTAssertTrue(shortcut.waitForExistence(timeout: 5))
    XCTAssertEqual(shortcut.label, "Player options")
    let portraitScreenshot = XCTAttachment(screenshot: app.screenshot())
    portraitScreenshot.name = "Portrait player shortcut"
    portraitScreenshot.lifetime = .keepAlways
    add(portraitScreenshot)
    shortcut.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.player.options"]
        .waitForExistence(timeout: 3)
    )
    app.buttons["Done"].tap()

    device.orientation = .landscapeLeft
    let hiddenInLandscape = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "exists == false"),
      object: shortcut
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [hiddenInLandscape], timeout: 3),
      .completed
    )
  }
}
