import XCTest

@MainActor
final class LiveIncomingLinkUITests: XCTestCase {
  private var server: LiveFixtureServer!

  override func setUpWithError() throws {
    continueAfterFailure = false
    server = LiveFixtureServer()
  }

  override func tearDown() {
    server.stop()
    server = nil
    super.tearDown()
  }

  func testLinkReceivedBeforeAuthenticationOpensInsideTypeType() throws {
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
      "--typetype-open-url",
      "typetype://watch?v=sm9",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["live.incoming-link"]
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      app.scrollViews["live.video.metadata"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(
      app.staticTexts["NicoNico video"]
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      app.otherElements["live.player.container"]
        .waitForExistence(timeout: 5)
    )

    let attachment = XCTAttachment(
      screenshot: XCUIScreen.main.screenshot()
    )
    attachment.name = "Live routing · Incoming NicoNico link"
    attachment.lifetime = .keepAlways
    add(attachment)
    app.terminate()
  }

  private func connect(
    _ app: XCUIApplication,
    address: String
  ) {
    let name = app.textFields["live.server.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("Local fixture")
    let url = app.textFields["live.server.url"]
    url.tap()
    url.typeText(address)
    app.swipeUp()
    let connect = app.buttons["live.server.connect"]
    XCTAssertTrue(connect.waitForExistence(timeout: 3))
    connect.tap()
    XCTAssertTrue(
      app.buttons["live.auth.guest"]
        .waitForExistence(timeout: 10)
    )
  }
}
