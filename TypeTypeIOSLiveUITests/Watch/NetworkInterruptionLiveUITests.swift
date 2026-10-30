import Foundation
import XCTest

@MainActor
final class NetworkInterruptionLiveUITests: XCTestCase {
  private var proxy: LiveInterruptingProxy!
  private var proxyURL: URL!

  override func setUpWithError() throws {
    continueAfterFailure = false
    proxy = LiveInterruptingProxy()
    proxyURL = try proxy.start()
  }

  override func tearDown() {
    proxy?.stop()
    proxy = nil
    proxyURL = nil
    super.tearDown()
  }

  func testRandomizedLongFormPlaybackStaysPlayingForFiveMinutes()
    throws
  {
    let query = [
      "Full technology documentary",
      "NASA full documentary",
      "Computer history documentary",
      "Open source documentary",
    ].randomElement() ?? "Full documentary"
    let app = launchConnectedApp()
    let selection = playLongFormResult(in: app, query: query)

    let position = app.otherElements["live.player.position"]
    XCTAssertTrue(position.waitForExistence(timeout: 10))
    let startingPosition = try XCTUnwrap(playbackPosition(from: position))
    var lastPosition = startingPosition
    var lastAdvance = Date()
    let deadline = Date().addingTimeInterval(300)
    var checks = 0
    while Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(5))
      XCTAssertEqual(app.state, .runningForeground)
      XCTAssertTrue(
        waitForPlayingPlayer(in: app, timeout: 15),
        app.debugDescription
      )
      let currentPosition = try XCTUnwrap(
        playbackPosition(from: position)
      )
      if currentPosition > lastPosition {
        lastPosition = currentPosition
        lastAdvance = Date()
      }
      XCTAssertLessThan(
        Date().timeIntervalSince(lastAdvance),
        15,
        "Long-form playback timeline stopped advancing."
      )
      checks += 1
    }
    XCTAssertGreaterThanOrEqual(
      lastPosition - startingPosition,
      285,
      "Five minutes elapsed without five minutes of media progress."
    )

    let report = XCTAttachment(
      string: """
      query=\(query)
      video=\(selection.identifier)
      declaredDuration=\(selection.duration) seconds
      playingChecks=\(checks)
      """
    )
    report.name = "Five-minute long-form playback"
    report.lifetime = .keepAlways
    add(report)
  }

  func testRandomizedSABRPlaybackRecoversAfterTransportCut()
    async throws
  {
    let query = [
      "Linux documentary",
      "Space technology",
      "Open source hardware",
      "Computer engineering",
      "Animation behind the scenes",
    ].randomElement() ?? "Technology"
    let app = launchConnectedApp()
    let videoID = playFirstResult(in: app, query: query)
    let position = app.otherElements["live.player.position"]
    XCTAssertTrue(position.waitForExistence(timeout: 10))
    let initialPosition = try XCTUnwrap(
      playbackPosition(from: position)
    )
    try await Task.sleep(for: .seconds(12))
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 15))
    XCTAssertGreaterThanOrEqual(
      try XCTUnwrap(playbackPosition(from: position))
        - initialPosition,
      8,
      "Playback did not advance before the transport interruption."
    )

    triggerNetworkCut(seconds: 30)
    try await Task.sleep(for: .seconds(45))

    XCTAssertEqual(app.state, .runningForeground)
    XCTAssertTrue(
      waitForPlayingPlayer(in: app, timeout: 90),
      app.debugDescription
    )
    let recoveredPosition = try XCTUnwrap(
      playbackPosition(from: position)
    )
    XCTAssertGreaterThan(
      recoveredPosition,
      initialPosition,
      "Recovery restarted or lost the playback timeline."
    )
    try await Task.sleep(for: .seconds(12))
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 15))
    let continuedPosition = try XCTUnwrap(
      playbackPosition(from: position)
    )
    XCTAssertGreaterThanOrEqual(
      continuedPosition - recoveredPosition,
      8,
      "Playback did not continue advancing after recovery."
    )
    let report = XCTAttachment(
      string: """
      query=\(query)
      video=\(videoID)
      interruption=30 seconds of closed proxy connections
      initialPosition=\(initialPosition)
      recoveredPosition=\(recoveredPosition)
      continuedPosition=\(continuedPosition)
      """
    )
    report.name = "Transport recovery selection"
    report.lifetime = .keepAlways
    add(report)
  }

  private func launchConnectedApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    let name = app.textFields["live.server.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("TypeType interrupted transport")
    let url = app.textFields["live.server.url"]
    url.tap()
    url.typeText(proxyURL.absoluteString)
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

  private func playFirstResult(
    in app: XCUIApplication,
    query: String
  ) -> String {
    app.searchTabButton.tap()
    let field = app.textFields["live.search.field"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(query)
    app.keyboards.buttons["Search"].tap()
    let result = app.buttons.matching(
      NSPredicate(
        format: "identifier BEGINSWITH %@",
        "live.home.video.card."
      )
    ).firstMatch
    XCTAssertTrue(result.waitForExistence(timeout: 120))
    for _ in 0..<8 where !result.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(result.isHittable, app.debugDescription)
    let identifier = result.identifier
    result.tap()
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 120))
    return identifier
  }

  private func playLongFormResult(
    in app: XCUIApplication,
    query: String
  ) -> (identifier: String, duration: Int) {
    app.searchTabButton.tap()
    let field = app.textFields["live.search.field"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(query)
    app.keyboards.buttons["Search"].tap()

    let results = app.buttons.matching(
      NSPredicate(
        format: "identifier BEGINSWITH %@",
        "live.home.video.card."
      )
    )
    XCTAssertTrue(results.firstMatch.waitForExistence(timeout: 120))
    var longResults: [(element: XCUIElement, duration: Int)] = []
    for index in 0..<min(results.count, 12) {
      let result = results.element(boundBy: index)
      let duration = durationSeconds(result.label)
      if duration >= 600 {
        longResults.append((result, duration))
      }
    }
    XCTAssertFalse(
      longResults.isEmpty,
      "Search did not expose a video longer than ten minutes."
    )
    let selection = longResults.randomElement()
      ?? (results.firstMatch, durationSeconds(results.firstMatch.label))
    for _ in 0..<12 where !selection.element.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(selection.element.isHittable, app.debugDescription)
    let identifier = selection.element.identifier
    selection.element.tap()
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 120))
    return (identifier, selection.duration)
  }

  private func durationSeconds(_ label: String) -> Int {
    let candidate = label.split {
      $0.isWhitespace || $0 == ","
    }.first {
      let components = $0.split(separator: ":")
      return (components.count == 2 || components.count == 3)
        && components.allSatisfy { Int($0) != nil }
    }
    let components = candidate?.split(separator: ":").compactMap {
      Int($0)
    } ?? []
    switch components.count {
    case 2:
      return components[0] * 60 + components[1]
    case 3:
      return components[0] * 3_600
        + components[1] * 60
        + components[2]
    default:
      return 0
    }
  }

  private func triggerNetworkCut(seconds: Int) {
    proxy.cutTransport(for: seconds)
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
      RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    } while Date() < deadline
    return false
  }

  private func playbackPosition(
    from element: XCUIElement
  ) -> TimeInterval? {
    livePlaybackPosition(from: element)
  }
}
