import XCTest

@MainActor
final class PlaybackLifecycleLiveUITests: XCTestCase {
  func launchConnectedApp(
    resetState: Bool
  ) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-live-ui"]
    if resetState {
      app.launchArguments.append("--typetype-reset-live-state")
    }
    app.launch()

    let name = app.textFields["live.server.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("TypeType production")
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
    return app
  }

  func playFirstResult(
    in app: XCUIApplication,
    query: String
  ) -> String {
    let search = app.buttons["live.home.search"]
    if search.waitForExistence(timeout: 5) {
      search.tap()
    }
    let field = app.searchFields["Search videos, channels..."]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    let clear = app.buttons["Clear text"]
    if clear.exists {
      clear.tap()
    }
    field.typeText(query)
    app.keyboards.buttons["Search"].tap()
    let result = app.buttons.matching(
      NSPredicate(
        format: "identifier BEGINSWITH %@",
        "live.home.video.card."
      )
    ).firstMatch
    XCTAssertTrue(result.waitForExistence(timeout: 120))
    for _ in 0..<6 where !result.isHittable {
      app.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(
      waitForHittable(result, timeout: 10),
      app.debugDescription
    )
    let identifier = result.identifier
    result.tap()
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 120))
    return identifier
  }

  func setAudioOnly(
    _ enabled: Bool,
    in app: XCUIApplication
  ) {
    let options = app.buttons["live.player.options"]
    XCTAssertTrue(options.waitForExistence(timeout: 5))
    options.tap()
    let sheet = app.descendants(matching: .any)[
      "live.player.options-sheet"
    ]
    XCTAssertTrue(sheet.waitForExistence(timeout: 5))
    let toggle = app.switches["Audio only"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    let current = toggle.value as? String == "1"
    if current != enabled {
      toggle.coordinate(
        withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
      ).tap()
    }
    XCTAssertTrue(
      waitForSwitch(toggle, enabled: enabled, timeout: 10),
      app.debugDescription
    )
    app.buttons["Done"].tap()
  }

  func verifyAudioOnly(
    _ enabled: Bool,
    in app: XCUIApplication
  ) {
    let options = app.buttons["live.player.options"]
    XCTAssertTrue(options.waitForExistence(timeout: 5))
    options.tap()
    let toggle = app.switches["Audio only"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    XCTAssertTrue(
      waitForSwitch(toggle, enabled: enabled, timeout: 10),
      app.debugDescription
    )
    app.buttons["Done"].tap()
  }

  func waitForHittable(
    _ element: XCUIElement,
    timeout: TimeInterval
  ) -> Bool {
    let predicate = NSPredicate(format: "hittable == true")
    let expectation = XCTNSPredicateExpectation(
      predicate: predicate,
      object: element
    )
    return XCTWaiter.wait(
      for: [expectation],
      timeout: timeout
    ) == .completed
  }

  func waitForSwitch(
    _ toggle: XCUIElement,
    enabled: Bool,
    timeout: TimeInterval
  ) -> Bool {
    let predicate = NSPredicate(
      format: "value == %@",
      enabled ? "1" : "0"
    )
    let expectation = XCTNSPredicateExpectation(
      predicate: predicate,
      object: toggle
    )
    return XCTWaiter.wait(
      for: [expectation],
      timeout: timeout
    ) == .completed
  }

  func waitForPlayingPlayer(
    in app: XCUIApplication,
    timeout: TimeInterval
  ) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    repeat {
      let player = app.otherElements["live.player.container"]
      if player.exists, player.value as? String == "playing" {
        return true
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    } while Date() < deadline
    return false
  }

  func hold(seconds: TimeInterval) {
    RunLoop.current.run(until: Date().addingTimeInterval(seconds))
  }

  @discardableResult
  func assertPlaybackAdvances(
    in app: XCUIApplication,
    seconds: TimeInterval
  ) -> TimeInterval {
    let position = app.otherElements["live.player.position"]
    XCTAssertTrue(position.waitForExistence(timeout: 10))
    guard let startingPosition = playbackPosition(from: position)
    else {
      XCTFail("Playback position is not numeric.")
      return 0
    }
    var lastPosition = startingPosition
    var lastAdvance = Date()
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
      hold(seconds: 1)
      XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 5))
      guard let currentPosition = playbackPosition(from: position)
      else {
        XCTFail("Playback position is not numeric.")
        return lastPosition
      }
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
      max(seconds - 8, seconds * 0.6),
      "Playback did not make enough real timeline progress."
    )
    return lastPosition
  }

  func playbackPosition(
    from element: XCUIElement
  ) -> TimeInterval? {
    livePlaybackPosition(from: element)
  }

  func randomQuery(offset: Int) -> String {
    randomQueries(count: 1, offset: offset)[0]
  }

  func randomQueries(
    count: Int,
    offset: Int = 0
  ) -> [String] {
    let queries = [
      "Technology documentary",
      "Open source",
      "Space exploration",
      "Computer history",
      "Animation short film",
      "Science experiment",
    ]
    let seed = Int.random(in: 0..<10_000)
    return (0..<count).map {
      queries[(seed + offset + $0) % queries.count]
    }
  }

  func attach(
    _ app: XCUIApplication,
    name: String,
    details: String
  ) {
    let report = XCTAttachment(string: details)
    report.name = name
    report.lifetime = .keepAlways
    add(report)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = name
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }
}
