import XCTest

final class UIDemoMoreTests: XCTestCase {
  func testMoreOpensPlaybackPreferences() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    app.tabBars.buttons["More"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.more.screen"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(app.staticTexts["Mock data · Offline"].exists)
    XCTAssertTrue(app.staticTexts["Import"].exists)

    app.staticTexts["Playback"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.more.playback"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.switches["Audio-only playback"].exists)

    app.navigationBars["Playback"].buttons.element(boundBy: 0).tap()
    app.staticTexts["Video"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.video-settings.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.staticTexts["SponsorBlock"].exists)
    XCTAssertTrue(app.switches["DeArrow titles and thumbnails"].exists)
  }

  func testDeArrowChangesHomeBrandingAndCanBeDisabled() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.staticTexts["Video"].tap()
    let deArrow = app.switches["DeArrow titles and thumbnails"]
    XCTAssertTrue(deArrow.waitForExistence(timeout: 3))
    XCTAssertEqual(deArrow.value as? String, "0")
    deArrow.coordinate(
      withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
    ).tap()
    XCTAssertEqual(deArrow.value as? String, "1")

    app.tabBars.buttons["Home"].tap()
    XCTAssertTrue(
      app.staticTexts["TypeType finally feels at home on iOS"]
        .waitForExistence(timeout: 3)
    )

    app.tabBars.buttons["More"].tap()
    app.switches["DeArrow titles and thumbnails"].coordinate(
      withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
    ).tap()
    app.tabBars.buttons["Home"].tap()
    XCTAssertTrue(
      app.staticTexts["A truly native TypeType for iPhone and iPad"]
        .waitForExistence(timeout: 3)
    )
  }
}
