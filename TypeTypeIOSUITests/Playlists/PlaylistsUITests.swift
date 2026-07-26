import XCTest

final class PlaylistsUITests: XCTestCase {
  func testCreatesPlaylistLocally() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-home"]
    app.launch()

    app.tabBars.buttons["Playlists"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.playlists.screen"]
        .waitForExistence(timeout: 5)
    )
    XCTAssertTrue(app.staticTexts["Saved public playlists"].exists)
    XCTAssertTrue(app.staticTexts["Favorites"].exists)

    app.buttons["demo.playlists.add"].tap()
    let name = app.textFields["demo.playlists.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 3))
    name.tap()
    name.typeText("Offline trips")
    app.buttons["demo.playlists.create"].tap()

    let created = app.staticTexts["Offline trips"]
    for _ in 0..<3 where !created.exists {
      app.swipeUp()
    }
    XCTAssertTrue(created.waitForExistence(timeout: 3))
  }
}
