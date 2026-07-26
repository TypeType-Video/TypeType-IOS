import XCTest

final class PlayerInteractionUITests: XCTestCase {
  func testCommentsLoadIncrementallyWhileScrolling() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let firstDeferredComment = app.staticTexts["@captionnerd"]
    XCTAssertFalse(
      firstDeferredComment.exists,
      "Comments after the first page must not be built immediately."
    )

    for _ in 0..<12 where !firstDeferredComment.exists {
      app.swipeUp()
    }
    XCTAssertTrue(
      firstDeferredComment.waitForExistence(timeout: 3),
      "Reaching the comment sentinel should request the next page automatically."
    )
    XCTAssertFalse(app.buttons["Load more comments"].exists)
  }

  func testPlaybackQueueUsesANativeSheet() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let queue = app.descendants(matching: .any)["demo.watch.queue"]
    for _ in 0..<5 where !queue.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(queue.waitForExistence(timeout: 3))
    XCTAssertTrue(queue.isHittable)
    queue.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.queue.sheet"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.navigationBars["Playback queue"].exists)
    XCTAssertTrue(app.buttons["Done"].exists)
    let queueScreenshot = XCTAttachment(screenshot: app.screenshot())
    queueScreenshot.name = "Native playback queue"
    queueScreenshot.lifetime = .keepAlways
    add(queueScreenshot)
  }

  func testMoreActionUsesAnAnchoredNativeMenu() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let actions = app.descendants(matching: .any)["demo.watch.actions"]
    XCTAssertTrue(actions.waitForExistence(timeout: 5))
    let more = app.buttons["demo.watch.more"]
    for _ in 0..<4 where !more.isHittable {
      actions.swipeLeft()
    }
    XCTAssertTrue(more.isHittable)
    more.tap()
    XCTAssertTrue(
      app.buttons["Add to Watch later"].waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.buttons["Block video"].exists)
    XCTAssertTrue(app.buttons["Block channel"].exists)
  }

  func testPlaylistEndUsesTheConfiguredAutoplayCountdown() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launchEnvironment["TYPETYPE_UI_TEST_PLAYER_ENDED"] = "1"
    app.launch()

    let countdown = app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Up next in ")
    ).firstMatch
    XCTAssertTrue(countdown.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["Play now"].exists)
    XCTAssertTrue(app.buttons["Cancel autoplay"].exists)
    let endScreen = XCTAttachment(screenshot: app.screenshot())
    endScreen.name = "Integrated playback end screen"
    endScreen.lifetime = .keepAlways
    add(endScreen)
  }

  func testPlayerReturnsToTopAfterRotation() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let player = app.descendants(matching: .any)["demo.player.surface"]
    XCTAssertTrue(player.waitForExistence(timeout: 5))
    XCUIDevice.shared.orientation = .landscapeLeft
    XCTAssertTrue(player.waitForExistence(timeout: 3))
    XCUIDevice.shared.orientation = .portrait
    XCTAssertTrue(player.waitForExistence(timeout: 3))
    XCTAssertTrue(player.isHittable)
  }
}
