import XCTest

final class LinkRoutingUITests: XCTestCase {
  func testSupportedVideoLinkStaysInsideTypeType() {
    let app = launchPlayer()
    expandDescription(in: app)

    let biliBili = app.buttons["BiliBili"]
    reveal(biliBili, in: app)
    biliBili.tap()

    XCTAssertTrue(
      app.staticTexts["Designing a calmer TypeType experience"]
        .waitForExistence(timeout: 4)
    )
    XCTAssertFalse(app.alerts["Attention: You’re leaving TypeType"].exists)
  }

  func testExternalLinkWarnsBeforeOpeningBrowser() {
    let app = launchPlayer()
    expandDescription(in: app)

    let project = app.buttons["Project page"]
    reveal(project, in: app)
    project.tap()

    let alert = app.alerts["Attention: You’re leaving TypeType"]
    XCTAssertTrue(alert.waitForExistence(timeout: 3))
    XCTAssertTrue(alert.buttons["Continue in browser"].exists)
    XCTAssertTrue(alert.buttons["Stay in TypeType"].exists)
  }

  func testAboutLinksWarnBeforeLeavingTypeType() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    for _ in 0..<6 where !app.staticTexts["About TypeType"].isHittable {
      app.swipeUp()
    }
    app.staticTexts["About TypeType"].tap()
    let github = app.buttons["TypeType on GitHub"]
    XCTAssertTrue(github.waitForExistence(timeout: 3))
    github.tap()

    let alert = app.alerts["Attention: You’re leaving TypeType"]
    XCTAssertTrue(alert.waitForExistence(timeout: 3))
    XCTAssertTrue(alert.buttons["Stay in TypeType"].exists)
  }

  private func launchPlayer() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.watch.screen"]
        .waitForExistence(timeout: 5)
    )
    return app
  }

  private func expandDescription(in app: XCUIApplication) {
    let showMore = app.buttons.matching(
      NSPredicate(
        format: "identifier == %@ AND label == %@",
        "demo.watch.description",
        "Show more"
      )
    ).firstMatch
    XCTAssertTrue(showMore.waitForExistence(timeout: 3))
    showMore.tap()
  }

  private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<14 where !element.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(element.waitForExistence(timeout: 3))
    XCTAssertTrue(element.isHittable)
  }
}
