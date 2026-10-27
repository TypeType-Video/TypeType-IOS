import XCTest

@MainActor
final class RandomizedLivePlaybackUITests: XCTestCase {
  func testRandomizedYouTubeVideoSwitching() {
    let seed = randomSeed
    let queries = [
      "Linus Tech Tips",
      "Veritasium",
      "Kurzgesagt",
      "Fireship",
      "NASA",
      "Blender Open Movie",
    ]
    let firstQuery = queries[seed % queries.count]
    let secondQuery = queries[(seed + 1) % queries.count]
    let app = launchConnectedApp()

    let firstID = playFirstResult(
      in: app,
      query: firstQuery,
      resultOffset: seed % 2
    )
    holdPlayback(in: app, seconds: 20)
    returnToSearch(in: app)

    let secondID = playFirstResult(
      in: app,
      query: secondQuery,
      resultOffset: (seed + 1) % 2
    )
    XCTAssertNotEqual(firstID, secondID)
    holdPlayback(in: app, seconds: 20)
    attachSelection(
      provider: "YouTube",
      queries: [firstQuery, secondQuery],
      videoIDs: [firstID, secondID],
      seed: seed
    )
  }

  func testRandomizedBiliBiliPlayback() {
    runProviderPlayback(
      provider: "BiliBili",
      serviceID: 5,
      queries: ["Linux", "Blender", "Apple", "open source"]
    )
  }

  func testRandomizedNicoNicoPlaybackAndMiniPlayerRoundTrip() {
    runProviderPlayback(
      provider: "NicoNico",
      serviceID: 6,
      queries: ["ゲーム", "音楽", "VOCALOID", "料理", "科学"],
      exercisesMiniPlayer: true
    )
  }

  private func runProviderPlayback(
    provider: String,
    serviceID: Int,
    queries: [String],
    exercisesMiniPlayer: Bool = false
  ) {
    let seed = randomSeed
    let query = queries[seed % queries.count]
    let app = launchConnectedApp()
    selectService(serviceID, named: provider, in: app)
    let videoID = playFirstResult(
      in: app,
      query: query,
      resultOffset: seed % 2
    )
    holdPlayback(in: app, seconds: 20)
    if exercisesMiniPlayer {
      returnToSearch(in: app)
      let miniPlayer = app.buttons["live.miniplayer.open"]
      XCTAssertTrue(miniPlayer.waitForExistence(timeout: 10))
      miniPlayer.tap()
      XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 45))
    }
    attachSelection(
      provider: provider,
      queries: [query],
      videoIDs: [videoID],
      seed: seed
    )
  }

  private var randomSeed: Int {
    let value = ProcessInfo.processInfo.environment[
      "TYPETYPE_RANDOM_SEED"
    ]
    return value.flatMap(Int.init) ?? Int.random(in: 0..<10_000)
  }

  private func launchConnectedApp() -> XCUIApplication {
    let liveURL = ProcessInfo.processInfo.environment[
      "TYPETYPE_LIVE_URL"
    ].flatMap { $0.isEmpty ? nil : $0 }
      ?? "https://watch.typetype.video"
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    let name = app.textFields["live.server.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("TypeType production")
    let url = app.textFields["live.server.url"]
    url.tap()
    url.typeText(liveURL)
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

  private func selectService(
    _ serviceID: Int,
    named provider: String,
    in app: XCUIApplication
  ) {
    let menu = app.buttons["live.home.service"]
    XCTAssertTrue(menu.waitForExistence(timeout: 10))
    menu.tap()
    let identified = app.buttons["live.home.service.\(serviceID)"]
    let service = identified.waitForExistence(timeout: 3)
      ? identified
      : app.buttons[provider]
    XCTAssertTrue(service.waitForExistence(timeout: 3))
    service.tap()
    RunLoop.current.run(until: Date().addingTimeInterval(2))
  }

  private func playFirstResult(
    in app: XCUIApplication,
    query: String,
    resultOffset: Int
  ) -> String {
    let searchButton = app.searchTabButton
    if searchButton.waitForExistence(timeout: 3) {
      searchButton.tap()
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

    let results = app.buttons.matching(
      NSPredicate(
        format: "identifier BEGINSWITH %@",
        "live.home.video.card."
      )
    )
    let first = results.firstMatch
    XCTAssertTrue(first.waitForExistence(timeout: 120))
    let available = max(min(results.count, 2), 1)
    let selected = results.element(boundBy: resultOffset % available)
    for _ in 0..<4 where !selected.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(selected.isHittable)
    let identifier = selected.identifier
    selected.tap()
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 120))
    return identifier
  }

  private func returnToSearch(in app: XCUIApplication) {
    let videoNavigation = app.navigationBars["Video"]
    XCTAssertTrue(videoNavigation.waitForExistence(timeout: 5))
    videoNavigation.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(
      app.buttons["live.miniplayer.open"]
        .waitForExistence(timeout: 10)
    )
  }

  private func holdPlayback(
    in app: XCUIApplication,
    seconds: TimeInterval
  ) {
    let position = app.otherElements["live.player.position"]
    XCTAssertTrue(position.waitForExistence(timeout: 10))
    guard let startingPosition = playbackPosition(from: position) else {
      return XCTFail("Playback position is not numeric.")
    }
    var lastPosition = startingPosition
    var lastAdvance = Date()
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(1))
      XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 5))
      guard let currentPosition = playbackPosition(from: position) else {
        return XCTFail("Playback position is not numeric.")
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
  }

  private func playbackPosition(
    from element: XCUIElement
  ) -> TimeInterval? {
    livePlaybackPosition(from: element)
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

  private func attachSelection(
    provider: String,
    queries: [String],
    videoIDs: [String],
    seed: Int
  ) {
    let report = """
    seed=\(seed)
    provider=\(provider)
    queries=\(queries.joined(separator: " | "))
    videos=\(videoIDs.joined(separator: " | "))
    """
    let attachment = XCTAttachment(string: report)
    attachment.name = "Randomized anti-cache selection"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
