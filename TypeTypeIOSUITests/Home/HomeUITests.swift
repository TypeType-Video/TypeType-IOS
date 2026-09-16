import XCTest

final class HomeUITests: XCTestCase {
  func testHomePresentsMockCatalogAndNativeTabs() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    XCTAssertTrue(
      app.otherElements["demo.home.brand"].waitForExistence(timeout: 3)
    )
    let usesiPadTabLayout = app.frame.width >= 600
    let homeTab = usesiPadTabLayout
      ? app.buttons["Home"].firstMatch
      : app.tabBars.buttons["Home"]
    let subscriptionsTab = usesiPadTabLayout
      ? app.buttons["Subscriptions"].firstMatch
      : app.tabBars.buttons["Subscriptions"]
    XCTAssertTrue(app.staticTexts["Continue watching"].exists)
    XCTAssertTrue(app.staticTexts["Recommended"].exists)
    XCTAssertTrue(homeTab.exists)
    XCTAssertTrue(subscriptionsTab.exists)
    XCTAssertTrue(
      app.buttons["demo.home.video.native-ios"].exists
    )
    XCTAssertFalse(app.buttons["Toggle playback mode"].exists)

    let recommendation = app.buttons["demo.home.video.native-ios"]
    XCTAssertLessThan(
      recommendation.frame.width,
      180,
      "Recommended thumbnails should remain compact on iPhone."
    )
    XCTAssertTrue(app.staticTexts["Duration 12:24"].exists)
    XCTAssertFalse(app.buttons["Load more recommendations"].exists)

    let loadedLater = app.buttons["demo.home.video.big-buck-restored"]
    for _ in 0..<4 where !loadedLater.exists {
      app.swipeUp()
    }
    XCTAssertTrue(loadedLater.waitForExistence(timeout: 3))

    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Compact home recommendations"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }
}
