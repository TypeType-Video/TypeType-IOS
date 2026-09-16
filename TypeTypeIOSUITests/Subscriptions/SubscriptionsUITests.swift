import XCTest

final class SubscriptionsUITests: XCTestCase {
  func testSubscriptionsSwitchesBetweenVideosAndChannels() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    app.tapTab("Subscriptions")
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.subscriptions.screen"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(app.staticTexts["5 channels followed"].exists)
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.subscriptions.videos"].exists
    )

    app.buttons["Channels"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.subscriptions.channel.blender"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.staticTexts["Blender Open Movies"].exists)
    XCTAssertTrue(app.staticTexts["TypeType"].exists)
  }
}
