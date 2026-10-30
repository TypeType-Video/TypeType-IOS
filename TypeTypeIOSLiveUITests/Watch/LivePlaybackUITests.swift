import AVKit
import XCTest

@MainActor
final class LivePlaybackUITests: XCTestCase {
  func testRandomizedFiveMinuteYouTubePlayback() throws {
    let candidates = [
      (
        searchQuery: "MKBHD",
        expectedVideoID: "zzjq7_ddb0U"
      ),
      (
        searchQuery: "GTA LaSalle",
        expectedVideoID: "mcV4qoX2MIE"
      ),
      (
        searchQuery: "MrBeast",
        expectedVideoID: "iYlODtkyw_I"
      ),
    ]
    let candidate = candidates.randomElement()!
    try runPlayback(
      searchQuery: candidate.searchQuery,
      expectedVideoID: candidate.expectedVideoID,
      holdSeconds: 300
    )
  }

  func testYouTubeSABRPlaybackReachesPlayingState() throws {
    try runPlayback(
      searchQuery: "Big Buck Bunny",
      expectedVideoID: "YE7VzlLtp-4"
    )
  }

  func testSustainedMKBHDPlayback() throws {
    try runPlayback(
      searchQuery: "MKBHD",
      expectedVideoID: "zzjq7_ddb0U",
      holdSeconds: 75
    )
  }

  func testSustainedLaSallePlayback() throws {
    try runPlayback(
      searchQuery: "GTA LaSalle",
      expectedVideoID: "mcV4qoX2MIE",
      holdSeconds: 75
    )
  }

  func testSustainedMrBeastPlayback() throws {
    try runPlayback(
      searchQuery: "MrBeast",
      expectedVideoID: "iYlODtkyw_I",
      holdSeconds: 75
    )
  }

  func testSustainedYouTubeLivePlayback() throws {
    try runPlayback(
      searchQuery: "NASA live",
      expectedVideoID: "awQzjn72bI0",
      holdSeconds: 60,
      expectsLive: true
    )
  }

  func testSustainedBiliBiliPlayback() throws {
    try runPlayback(
      searchQuery: "BV1xx411c7mD",
      expectedVideoID: "BV1xx411c7mD",
      serviceID: 5,
      serviceName: "BiliBili",
      holdSeconds: 30
    )
  }

  func testSustainedBiliBiliAkamaiPlayback() throws {
    try runPlayback(
      searchQuery: "BV1cN411d74Q",
      expectedVideoID: "BV1cN411d74Q",
      serviceID: 5,
      serviceName: "BiliBili",
      holdSeconds: 30
    )
  }

  func testSustainedBiliBiliLargeAkamaiRangesPlayback() throws {
    try runPlayback(
      searchQuery: "BV12V3v66E3B",
      expectedVideoID: "BV12V3v66E3B",
      serviceID: 5,
      serviceName: "BiliBili",
      holdSeconds: 30
    )
  }

  func testSustainedNicoNicoPlayback() throws {
    try runPlayback(
      searchQuery: "Windrose",
      expectedVideoID: "sm46594288",
      serviceID: 6,
      serviceName: "NicoNico",
      holdSeconds: 30
    )
  }

  func testSustainedNicoNicoSignedHLSPlayback() throws {
    try runPlayback(
      searchQuery: "死んでみた 箱庭コト",
      expectedVideoID: "sm46589126",
      serviceID: 6,
      serviceName: "NicoNico",
      holdSeconds: 60
    )
  }

  func testNativeFullscreenRoundTripKeepsPlaying() throws {
    try runPlayback(
      searchQuery: "GTA LaSalle",
      expectedVideoID: "mcV4qoX2MIE",
      exercisesFullscreen: true
    )
  }

  func testNativePictureInPictureStarts() throws {
    guard AVPictureInPictureController.isPictureInPictureSupported()
    else {
      throw XCTSkip(
        "Picture in Picture is unavailable on this simulator runtime."
      )
    }
    try runPlayback(
      searchQuery: "MKBHD",
      expectedVideoID: "zzjq7_ddb0U",
      exercisesPictureInPicture: true
    )
  }

  private func runPlayback(
    searchQuery: String,
    expectedVideoID: String,
    serviceID: Int? = nil,
    serviceName: String? = nil,
    holdSeconds: TimeInterval = 0,
    exercisesFullscreen: Bool = false,
    exercisesPictureInPicture: Bool = false,
    expectsLive: Bool = false
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
      RunLoop.current.run(
        until: Date().addingTimeInterval(2)
      )
    }

    app.searchTabButton.tap()
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

    if expectsLive {
      let statistics = app.staticTexts["live.video.statistics"]
      XCTAssertTrue(statistics.waitForExistence(timeout: 10))
      XCTAssertTrue(
        statistics.label.localizedCaseInsensitiveContains("Live"),
        "The selected result did not open as a live stream."
      )
    }

    if exercisesFullscreen {
      try exerciseFullscreen(app)
    }
    if exercisesPictureInPicture {
      defer { app.terminate() }
      try exercisePictureInPicture(app, player: player)
      return
    }

    if holdSeconds > 0 {
      try assertSustainedPlayback(
        in: app,
        seconds: holdSeconds
      )
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

  private func assertSustainedPlayback(
    in app: XCUIApplication,
    seconds: TimeInterval
  ) throws {
    let position = app.otherElements["live.player.position"]
    XCTAssertTrue(position.waitForExistence(timeout: 10))
    let startingPosition = try playbackPosition(from: position)
    var lastPosition = startingPosition
    var lastAdvance = Date()
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
      RunLoop.current.run(
        until: Date().addingTimeInterval(2)
      )
      XCTAssertEqual(app.state, .runningForeground)
      XCTAssertTrue(
        waitForPlayingPlayer(in: app, timeout: 2),
        "Playback buffered for more than two seconds."
      )
      let currentPosition = try playbackPosition(from: position)
      if currentPosition > lastPosition {
        lastPosition = currentPosition
        lastAdvance = Date()
      }
      XCTAssertLessThan(
        Date().timeIntervalSince(lastAdvance),
        8,
        "Playback reported playing while its timeline was stalled."
      )
    }
    XCTAssertGreaterThanOrEqual(
      lastPosition - startingPosition,
      max(seconds - 8, seconds * 0.65),
      "Playback did not make enough real timeline progress."
    )
  }

  private func playbackPosition(
    from element: XCUIElement
  ) throws -> TimeInterval {
    try XCTUnwrap(
      livePlaybackPosition(from: element),
      "Unexpected playback position: \(String(describing: element.value))"
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
      XCTAssertTrue(revealAVKitCloseControl(in: app))
      if cycle == 1 {
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(revealAVKitCloseControl(in: app))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(
          revealAVKitCloseControl(in: app),
          app.debugDescription
        )
      }
      XCTAssertTrue(
        revealAVKitCloseControl(in: app),
        app.debugDescription
      )
      app.coordinate(
        withNormalizedOffset: CGVector(dx: 0.08, dy: 0.095)
      ).tap()
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

  private func revealAVKitCloseControl(
    in app: XCUIApplication
  ) -> Bool {
    for _ in 0..<4 {
      let control = app.buttons["Close Button"]
      if control.exists, !control.frame.isEmpty {
        return true
      }
      app.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
      ).tap()
      let refreshed = app.buttons["Close Button"]
      if refreshed.waitForExistence(timeout: 2),
        !refreshed.frame.isEmpty {
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
