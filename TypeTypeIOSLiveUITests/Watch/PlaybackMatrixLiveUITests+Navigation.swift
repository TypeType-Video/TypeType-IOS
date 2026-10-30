import XCTest

@MainActor
extension PlaybackMatrixLiveUITests {
  func launchMatrixApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    let name = app.textFields["live.server.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("TypeType playback matrix")
    let url = app.textFields["live.server.url"]
    url.tap()
    url.typeText("https://watch.typetype.video")
    app.swipeUp()
    app.buttons["live.server.connect"].tap()
    let guest = app.buttons["live.auth.guest"]
    XCTAssertTrue(guest.waitForExistence(timeout: 20))
    guest.tap()
    XCTAssertTrue(
      app.otherElements["live.home.screen"]
        .waitForExistence(timeout: 20)
    )
    app.searchTabButton.tap()
    XCTAssertTrue(
      app.textFields["live.search.field"]
        .waitForExistence(timeout: 10)
    )
    return app
  }

  func selectMatrixService(
    _ provider: String,
    in app: XCUIApplication
  ) throws {
    var service = app.buttons["live.search.service"]
    let selectsFromSearch = service.waitForExistence(timeout: 3)
    if !selectsFromSearch {
      let close = app.navigationBars["Search"].buttons["Close"]
      XCTAssertTrue(close.waitForExistence(timeout: 10))
      close.tap()
      service = app.buttons["live.home.service"]
    }
    XCTAssertTrue(service.waitForExistence(timeout: 10))
    service.tap()
    let option = matrixElement(labelled: provider, in: app)
    XCTAssertTrue(option.waitForExistence(timeout: 5))
    option.tap()
    RunLoop.current.run(until: Date().addingTimeInterval(2))
    if !selectsFromSearch {
      app.searchTabButton.tap()
      XCTAssertTrue(
        app.textFields["live.search.field"]
          .waitForExistence(timeout: 10)
      )
    }
  }

  func openMatrixVideo(
    _ scenario: LivePlaybackMatrixCase,
    in app: XCUIApplication
  ) throws -> String {
    let field = app.textFields["live.search.field"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    let clear = app.buttons["Clear text"]
    if clear.exists {
      clear.tap()
    }
    field.typeText(scenario.query)
    app.keyboards.buttons["Search"].tap()

    let result = app.buttons.matching(
      NSPredicate(
        format: "identifier CONTAINS %@",
        scenario.expectedID
      )
    ).firstMatch
    XCTAssertTrue(
      waitForMatrixResult(result, in: app),
      "Missing \(scenario.expectedID) for \(scenario.query)."
    )
    let identifier = result.identifier
    result.tap()
    XCTAssertTrue(
      waitForMatrixPlayback(in: app, timeout: 120),
      "Playback did not start for \(scenario.expectedID)."
    )
    return identifier
  }

  func closeMatrixVideo(
    in app: XCUIApplication,
    closePlayback: Bool = true
  ) {
    let navigation = app.navigationBars["Video"]
    XCTAssertTrue(navigation.waitForExistence(timeout: 10))
    navigation.buttons.element(boundBy: 0).tap()
    guard closePlayback else { return }
    let close = app.buttons["live.miniplayer.close"]
    XCTAssertTrue(close.waitForExistence(timeout: 10))
    close.tap()
  }

  private func waitForMatrixResult(
    _ result: XCUIElement,
    in app: XCUIApplication
  ) -> Bool {
    let anyResult = app.buttons.matching(
      NSPredicate(
        format: "identifier BEGINSWITH %@",
        "live.home.video.card."
      )
    ).firstMatch
    guard anyResult.waitForExistence(timeout: 120) else {
      return false
    }
    for _ in 0..<10 {
      if result.exists, result.isHittable {
        return true
      }
      app.swipeUp()
    }
    return result.exists && result.isHittable
  }

  func matrixElement(
    labelled label: String,
    in app: XCUIApplication
  ) -> XCUIElement {
    app.descendants(matching: .any).matching(
      NSPredicate(format: "label == %@", label)
    ).firstMatch
  }
}
