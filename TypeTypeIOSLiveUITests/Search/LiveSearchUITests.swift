import XCTest

@MainActor
final class LiveSearchUITests: XCTestCase {
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

  func testSearchChannelPaginationAndSubscriptionFlow() async throws {
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()
    let searchButton = app.buttons["live.home.search"]
    XCTAssertTrue(searchButton.waitForExistence(timeout: 10))
    searchButton.tap()

    let field = app.searchFields[
      "Search videos, channels..."
    ]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText("Backend search")
    app.keyboards.buttons["Search"].tap()

    XCTAssertTrue(
      element(in: app, labelled: "Backend search result")
        .waitForExistence(timeout: 15)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Search page two")
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Blender Fixture").exists
    )
    XCTAssertTrue(
      element(in: app, labelled: "Backend playlist").exists
    )
    XCTAssertTrue(
      element(in: app, labelled: "Search short video").exists
    )
    capture(app, named: "Live search · Mixed backend results")

    let channel = app.buttons.matching(
      identifier: "live.search.channel"
    ).firstMatch
    XCTAssertTrue(channel.isHittable)
    channel.tap()
    XCTAssertTrue(
      element(in: app, labelled: "Blender Fixture")
        .waitForExistence(timeout: 15)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Channel backend video")
        .waitForExistence(timeout: 10)
    )
    let secondChannelVideo = element(
      in: app,
      labelled: "Channel page two"
    )
    for _ in 0..<5 where !secondChannelVideo.exists {
      app.swipeUp()
    }
    XCTAssertTrue(secondChannelVideo.waitForExistence(timeout: 10))
    XCTAssertTrue(
      element(in: app, labelled: "Backend podcast").exists
    )

    for _ in 0..<5 {
      app.swipeDown()
    }
    let subscription = app.buttons[
      "live.channel.subscription"
    ]
    XCTAssertTrue(subscription.waitForExistence(timeout: 3))
    XCTAssertTrue(subscription.isHittable)
    subscription.tap()
    XCTAssertTrue(
      app.buttons.matching(
        NSPredicate(format: "label == %@", "Subscribed")
      ).firstMatch.waitForExistence(timeout: 5)
    )

    let sortMenu = app.buttons["live.channel.sort"]
    XCTAssertEqual(sortMenu.value as? String, "Newest")
    sortMenu.tap()
    app.buttons["Popular"].firstMatch.tap()
    XCTAssertEqual(sortMenu.value as? String, "Popular")
    capture(app, named: "Live channel · Popular video order")

    app.buttons["live.channel.tabs"].tap()
    app.buttons["Playlists"].firstMatch.tap()
    XCTAssertTrue(
      element(in: app, labelled: "Backend playlist")
        .waitForExistence(timeout: 10)
    )
    XCTAssertEqual(
      app.buttons["live.channel.tabs"].value as? String,
      "Playlists"
    )
    capture(app, named: "Live channel · Playlists and subscription")
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
    let attachment = XCTAttachment(screenshot: app.screenshot())
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
}
