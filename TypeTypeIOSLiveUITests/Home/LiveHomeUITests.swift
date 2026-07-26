import XCTest

@MainActor
final class LiveHomeUITests: XCTestCase {
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

  func testBackendFeedPaginationServiceAndMetadata() async throws {
    let serverURL = try server.start()
    let probeURL = serverURL
      .appending(path: "api")
      .appending(path: "instance")
    let (_, response) = try await URLSession.shared.data(
      from: probeURL
    )
    XCTAssertEqual(
      (response as? HTTPURLResponse)?.statusCode,
      200
    )
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()

    let firstCard = app.buttons.matching(
      identifier: "live.home.video.card"
    ).firstMatch
    XCTAssertTrue(firstCard.waitForExistence(timeout: 15))
    XCTAssertTrue(
      element(in: app, labelled: "Backend recommendation")
        .waitForExistence(timeout: 3)
    )
    XCTAssertFalse(
      element(in: app, labelled: "Filtered short").exists
    )
    XCTAssertTrue(
      element(in: app, labelled: "Loaded automatically")
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      app.otherElements["live.home.loading-more"]
        .waitForNonExistence(timeout: 3)
    )
    let loadingIndicator = app.activityIndicators[
      "Loading more recommendations"
    ]
    if loadingIndicator.exists {
      XCTAssertTrue(
        loadingIndicator.waitForNonExistence(timeout: 3)
      )
    }
    capture(app, named: "Live home · Backend recommendations")

    firstCard.tap()
    XCTAssertTrue(
      app.scrollViews["live.video.metadata"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      app.staticTexts["A backend fixture video."].exists
    )
    app.navigationBars["Video"].buttons.firstMatch.tap()

    app.tabBars.buttons["More"].tap()
    let settings = element(in: app, labelled: "Settings")
    XCTAssertTrue(settings.waitForExistence(timeout: 3))
    settings.tap()
    let settingsScreen = app.collectionViews[
      "live.settings.screen"
    ]
    XCTAssertTrue(settingsScreen.waitForExistence(timeout: 5))
    let servicePicker = app.buttons.matching(
      NSPredicate(
        format: "label CONTAINS[c] %@",
        "Default service"
      )
    ).firstMatch
    for _ in 0..<3 where !servicePicker.exists {
      settingsScreen.swipeUp()
    }
    XCTAssertTrue(servicePicker.waitForExistence(timeout: 5))
    servicePicker.tap()
    capture(app, named: "Live settings · Service picker")
    let springboard = XCUIApplication(
      bundleIdentifier: "com.apple.springboard"
    )
    let bilibili = try XCTUnwrap(
      firstElement(
        [
          element(in: app, labelled: "BiliBili"),
          element(in: springboard, labelled: "BiliBili"),
        ],
        timeout: 3
      )
    )
    bilibili.tap()
    let save = app.buttons["live.settings.save"]
    XCTAssertTrue(save.waitForExistence(timeout: 3))
    save.tap()
    let saveDeadline = Date().addingTimeInterval(5)
    while save.isEnabled, Date() < saveDeadline {
      RunLoop.current.run(
        until: Date().addingTimeInterval(0.1)
      )
    }
    XCTAssertFalse(save.isEnabled)
    app.tabBars.buttons["Home"].tap()
    XCTAssertTrue(
      element(in: app, labelled: "BiliBili recommendation")
        .waitForExistence(timeout: 10)
    )
    capture(app, named: "Live home · BiliBili service")
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

  private func capture(_ app: XCUIApplication, named name: String) {
    let attachment = XCTAttachment(
      screenshot: XCUIScreen.main.screenshot()
    )
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func element(
    in app: XCUIApplication,
    labelled label: String
  ) -> XCUIElement {
    app.descendants(matching: .any)
      .matching(NSPredicate(format: "label == %@", label))
      .firstMatch
  }

  private func firstElement(
    _ candidates: [XCUIElement],
    timeout: TimeInterval
  ) -> XCUIElement? {
    let deadline = Date().addingTimeInterval(timeout)
    repeat {
      if let element = candidates.first(where: \.exists) {
        return element
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    } while Date() < deadline
    return nil
  }
}
