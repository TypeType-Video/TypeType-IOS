import XCTest

final class UIDemoHistoryTests: XCTestCase {
  func testHistorySearchesMockEntriesLocally() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    app.tabBars.buttons["History"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.history.screen"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(app.staticTexts["Today"].exists)
    XCTAssertTrue(
      app.staticTexts["Big Buck Bunny — Blender Open Movie"].exists
    )

    let search = app.searchFields["Search history"]
    XCTAssertTrue(search.waitForExistence(timeout: 3))
    search.tap()
    search.typeText("SABR")

    XCTAssertTrue(
      app.staticTexts[
        "SABR explained: resilient playback from first principles"
      ].waitForExistence(timeout: 3)
    )
    XCTAssertFalse(
      app.staticTexts["Big Buck Bunny — Blender Open Movie"].exists
    )
  }

  func testHistoryRemovalMenuIsAnchoredToItsVideo() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    app.tabBars.buttons["History"].tap()
    let actions = app.buttons[
      "History actions for Big Buck Bunny — Blender Open Movie"
    ]
    XCTAssertTrue(actions.waitForExistence(timeout: 5))
    actions.tap()

    let remove = app.buttons["Remove from history"]
    XCTAssertTrue(remove.waitForExistence(timeout: 3))
    remove.tap()
    XCTAssertFalse(
      app.staticTexts["Big Buck Bunny — Blender Open Movie"]
        .waitForExistence(timeout: 1)
    )
  }
}
