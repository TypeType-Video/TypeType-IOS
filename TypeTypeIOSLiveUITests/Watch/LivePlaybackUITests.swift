import AVKit
import XCTest

@MainActor
final class LivePlaybackUITests: XCTestCase {
  func testYouTubeSABRPlaybackReachesPlayingState() throws {
    try runPlayback(
      searchQuery: "Big Buck Bunny",
      expectedVideoID: "YE7VzlLtp-4"
    )
  }

  private func runPlayback(
    searchQuery: String,
    expectedVideoID: String,
    serviceID: Int? = nil,
    serviceName: String? = nil,
    holdSeconds: TimeInterval = 0,
    exercisesFullscreen: Bool = false,
    exercisesPictureInPicture: Bool = false
  ) throws {
    let environment = ProcessInfo.processInfo.environment
    let liveURL = environment["TYPETYPE_LIVE_URL"]
      .flatMap { $0.isEmpty ? nil : $0 }
      ?? "https://watch.typetype.video"

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

    if let serviceID, let serviceName {
      let serviceMenu = app.buttons["live.home.service"]
      XCTAssertTrue(serviceMenu.waitForExistence(timeout: 10))
      serviceMenu.tap()
      let service = app.buttons["live.home.service.\(serviceID)"]
      if service.waitForExistence(timeout: 3) {
        service.tap()
      } else {
        let fallback = app.buttons[serviceName]
        XCTAssertTrue(fallback.waitForExistence(timeout: 3))
        fallback.tap()
      }
      // Service selection refreshes the home feed asynchronously. Let that
      // navigation-bar update settle before presenting the search surface.
      RunLoop.current.run(
        until: Date().addingTimeInterval(2)
      )
    }

    app.buttons["live.home.search"].tap()
    let field = app.searchFields["Search videos, channels..."]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(searchQuery)
    app.keyboards.buttons["Search"].tap()

    let expectedVideo = app.buttons.matching(
      NSPredicate(
        format: "identifier CONTAINS %@",
        expectedVideoID
      )
    ).firstMatch
    XCTAssertTrue(
      waitForSearchResult(expectedVideo, in: app),
      "Search did not return the expected video \(expectedVideoID)."
    )
    expectedVideo.tap()

    let player = app.otherElements["live.player.container"]
    XCTAssertTrue(player.waitForExistence(timeout: 15))
    let playing = NSPredicate(format: "value == %@", "playing")
    expectation(
      for: playing,
      evaluatedWith: player
    )
    waitForExpectations(timeout: 120)

    if exercisesFullscreen {
      try exerciseFullscreen(app)
    }
    if exercisesPictureInPicture {
      defer { app.terminate() }
      try exercisePictureInPicture(app, player: player)
      return
    }

    if holdSeconds > 0 {
      let hold = expectation(description: "Sustained SABR playback")
      DispatchQueue.main.asyncAfter(deadline: .now() + holdSeconds) {
        hold.fulfill()
      }
      wait(for: [hold], timeout: holdSeconds + 5)
      expectation(for: playing, evaluatedWith: player)
      waitForExpectations(timeout: 30)
    }

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Live \(serviceName ?? "YouTube SABR") playback"
    attachment.lifetime = .keepAlways
    add(attachment)

    let videoNavigation = app.navigationBars["Video"]
    XCTAssertTrue(videoNavigation.waitForExistence(timeout: 5))
    videoNavigation.buttons.element(boundBy: 0).tap()

    let miniPlayer = app.buttons["live.miniplayer.open"]
    XCTAssertTrue(miniPlayer.waitForExistence(timeout: 10))
    XCTAssertTrue(miniPlayer.isHittable)
    let miniAttachment = XCTAttachment(screenshot: app.screenshot())
    miniAttachment.name = "Live \(serviceName ?? "SABR") mini player"
    miniAttachment.lifetime = .keepAlways
    add(miniAttachment)

    miniPlayer.tap()
    XCTAssertTrue(player.waitForExistence(timeout: 10))
    XCTAssertTrue(
      waitForPlayingPlayer(in: app, timeout: 30),
      app.debugDescription
    )
  }

  private func waitForSearchResult(
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
    if result.exists, result.isHittable {
      return true
    }
    for _ in 0..<8 {
      app.swipeUp()
      if result.waitForExistence(timeout: 3), result.isHittable {
        return true
      }
    }
    return false
  }

  private func exercisePictureInPicture(
    _ app: XCUIApplication,
    player: XCUIElement
  ) throws {
    player.coordinate(
      withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)
    ).tap()
    let enterFullscreen = app.buttons["Fullscreen Button"]
    guard enterFullscreen.waitForExistence(timeout: 5) else {
      XCTFail(app.debugDescription)
      return
    }
    enterFullscreen.tap()
    let closeFullscreen = app.buttons["Close Button"]
    if !closeFullscreen.waitForExistence(timeout: 2) {
      app.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
      ).tap()
    }
    guard closeFullscreen.waitForExistence(timeout: 5) else {
      XCTFail(app.debugDescription)
      return
    }

    var pictureInPictureButton = app.buttons.matching(
      NSPredicate(
        format: "label CONTAINS[c] %@",
        "picture in picture"
      )
    ).firstMatch
    if !pictureInPictureButton.waitForExistence(timeout: 3) {
      let moreControls = app.buttons.matching(
        NSPredicate(
          format: "label CONTAINS[c] %@",
          "more controls"
        )
      ).firstMatch
      guard moreControls.waitForExistence(timeout: 3) else {
        XCTFail(app.debugDescription)
        return
      }
      moreControls.tap()
      pictureInPictureButton = app.buttons.matching(
        NSPredicate(
          format: "label CONTAINS[c] %@",
          "picture in picture"
        )
      ).firstMatch
    }
    guard pictureInPictureButton.waitForExistence(timeout: 5) else {
      XCTFail(app.debugDescription)
      return
    }
    pictureInPictureButton.tap()
    XCTAssertEqual(app.state, .runningForeground)

    let springboard = XCUIApplication(
      bundleIdentifier: "com.apple.springboard"
    )
    let systemPictureInPictureControl = springboard.buttons.matching(
      NSPredicate(
        format: "label CONTAINS[c] %@",
        "picture in picture"
      )
    ).firstMatch
    XCTAssertTrue(
      systemPictureInPictureControl.waitForExistence(timeout: 10),
      springboard.debugDescription
    )
  }

  private func exerciseFullscreen(
    _ app: XCUIApplication
  ) throws {
    addTeardownBlock {
      XCUIDevice.shared.orientation = .portrait
    }
    for cycle in 0..<3 {
      let inlinePlayer = app.otherElements["live.player.container"]
      XCTAssertTrue(inlinePlayer.waitForExistence(timeout: 10))
      inlinePlayer.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)
      ).tap()
      if app.buttons["Play/Pause"].label == "Play" {
        app.buttons["Play/Pause"].tap()
        XCTAssertTrue(
          waitForPlayingPlayer(in: app, timeout: 15),
          app.debugDescription
        )
      }
      let enter = app.buttons["Fullscreen Button"]
      XCTAssertTrue(
        enter.waitForExistence(timeout: 5),
        app.debugDescription
      )
      enter.tap()
      XCTAssertEqual(app.state, .runningForeground)

      app.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
      ).tap()
      let exit = app.buttons["Close Button"]
      XCTAssertTrue(
        exit.waitForExistence(timeout: 5),
        app.debugDescription
      )
      if cycle == 1 {
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(exit.waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(
          revealAVKitControl(exit, in: app),
          app.debugDescription
        )
      }
      XCTAssertTrue(
        revealAVKitControl(exit, in: app),
        app.debugDescription
      )
      exit.tap()
      XCTAssertEqual(app.state, .runningForeground)
      XCTAssertTrue(
        waitForPlayingPlayer(in: app, timeout: 20),
        app.debugDescription
      )
    }
  }

  private func waitForPlayingPlayer(
    in app: XCUIApplication,
    timeout: TimeInterval
  ) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    repeat {
      let player = app.otherElements["live.player.container"]
      if player.exists, player.value as? String == "playing" {
        return true
      }
      RunLoop.current.run(
        until: Date().addingTimeInterval(0.2)
      )
    } while Date() < deadline
    return false
  }

  private func revealAVKitControl(
    _ control: XCUIElement,
    in app: XCUIApplication
  ) -> Bool {
    for _ in 0..<4 {
      if control.exists, control.isHittable {
        return true
      }
      app.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
      ).tap()
      if control.waitForExistence(timeout: 2) {
        return true
      }
    }
    return false
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
