import XCTest

@MainActor
final class LivePlaybackUITests: XCTestCase {
  func testYouTubeSABRPlaybackReachesPlayingState() throws {
    let environment = ProcessInfo.processInfo.environment
    let liveURL = environment["TYPETYPE_LIVE_URL"]
      .flatMap { $0.isEmpty ? nil : $0 }
      ?? "https://beta.typetype.video"

    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: liveURL)
    let guest = app.buttons["live.auth.guest"]
    XCTAssertTrue(guest.waitForExistence(timeout: 15))
    guest.tap()
    XCTAssertTrue(
      app.otherElements["live.home.screen"]
        .waitForExistence(timeout: 20)
    )

    app.buttons["live.home.search"].tap()
    let field = app.searchFields["Search videos, channels..."]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText("Big Buck Bunny")
    app.keyboards.buttons["Search"].tap()

    let firstVideo = app.buttons.matching(
      identifier: "live.home.video.card"
    ).firstMatch
    XCTAssertTrue(firstVideo.waitForExistence(timeout: 120))
    firstVideo.tap()

    let player = app.otherElements["live.player.container"]
    XCTAssertTrue(player.waitForExistence(timeout: 15))
    let playing = NSPredicate(format: "value == %@", "playing")
    expectation(
      for: playing,
      evaluatedWith: player
    )
    waitForExpectations(timeout: 120)

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Live YouTube SABR playback"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func connect(
    _ app: XCUIApplication,
    address: String
  ) {
    let name = app.textFields["live.server.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("TypeType beta")

    let url = app.textFields["live.server.url"]
    url.tap()
    url.typeText(address)
    app.swipeUp()

    let connect = app.buttons["live.server.connect"]
    XCTAssertTrue(connect.waitForExistence(timeout: 3))
    connect.tap()
    XCTAssertTrue(
      app.buttons["live.auth.submit"]
        .waitForExistence(timeout: 20)
    )
  }
}
