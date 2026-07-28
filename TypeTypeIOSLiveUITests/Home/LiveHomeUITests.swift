import XCTest

@MainActor
final class LiveHomeUITests: XCTestCase {
  private var server: LiveFixtureServer!

  override func setUpWithError() throws {
    continueAfterFailure = false
    server = LiveFixtureServer()
  }

  override func tearDown() {
    server.stop()
    server = nil
    super.tearDown()
  }

  func testBackendFeedPaginationServiceAndMetadata() async throws {
    let serverURL = try server.start()
    let probeURL = serverURL
      .appending(path: "api")
      .appending(path: "instance")
    let (_, response) = try await URLSession.shared.data(
      from: probeURL
    )
    XCTAssertEqual(
      (response as? HTTPURLResponse)?.statusCode,
      200
    )
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()

    let videoCards = app.buttons.matching(
      NSPredicate(
        format: "identifier BEGINSWITH %@",
        "live.home.video.card."
      )
    )
    let firstCard = videoCards.firstMatch
    XCTAssertTrue(firstCard.waitForExistence(timeout: 15))
    XCTAssertTrue(
      element(in: app, labelled: "Backend recommendation")
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Short video").exists
    )
    XCTAssertTrue(
      element(in: app, labelled: "Loaded automatically")
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      app.otherElements["live.home.loading-more"]
        .waitForNonExistence(timeout: 3)
    )
    let loadingIndicator = app.activityIndicators[
      "Loading more recommendations"
    ]
    if loadingIndicator.exists {
      XCTAssertTrue(
        loadingIndicator.waitForNonExistence(timeout: 3)
      )
    }
    capture(app, named: "Live home · Backend recommendations")

    let shortCard = app.buttons["live.home.video.card.short-1"]
    XCTAssertTrue(shortCard.isHittable)
    shortCard.tap()
    XCTAssertTrue(
      app.scrollViews["live.video.metadata"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      app.staticTexts["A backend fixture video."].exists
    )
    let playerOptions = app.buttons["live.player.options"]
    XCTAssertTrue(playerOptions.waitForExistence(timeout: 3))
    playerOptions.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.player.options-sheet"]
        .waitForExistence(timeout: 3)
    )
    let sleepTimer = app.buttons[
      "live.player.sleep-timer.open"
    ]
    XCTAssertTrue(sleepTimer.waitForExistence(timeout: 3))
    sleepTimer.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.player.sleep-timer"]
        .waitForExistence(timeout: 3)
    )
    app.buttons["15 minutes"].tap()
    XCTAssertTrue(
      app.buttons["15 minutes"]
        .waitForExistence(timeout: 3)
    )
    capture(app, named: "Live player · Active sleep timer")
    app.navigationBars["Sleep timer"].buttons.firstMatch.tap()
    XCTAssertTrue(
      app.buttons["live.player.sleep-timer.open"]
        .waitForExistence(timeout: 3)
    )
    app.buttons["Done"].tap()
    app.navigationBars["Video"].buttons.firstMatch.tap()

    app.tabBars.buttons["More"].tap()
    let settings = element(in: app, labelled: "Settings")
    XCTAssertTrue(settings.waitForExistence(timeout: 3))
    settings.tap()
    let settingsScreen = app.collectionViews[
      "live.settings.screen"
    ]
    XCTAssertTrue(settingsScreen.waitForExistence(timeout: 5))
    let servicePicker = app.buttons.matching(
      NSPredicate(
        format: "label CONTAINS[c] %@",
        "Default service"
      )
    ).firstMatch
    for _ in 0..<3 where !servicePicker.exists {
      settingsScreen.swipeUp()
    }
    XCTAssertTrue(servicePicker.waitForExistence(timeout: 5))
    servicePicker.tap()
    capture(app, named: "Live settings · Service picker")
    let springboard = XCUIApplication(
      bundleIdentifier: "com.apple.springboard"
    )
    let bilibili = try XCTUnwrap(
      firstElement(
        [
          element(in: app, labelled: "BiliBili"),
          element(in: springboard, labelled: "BiliBili"),
        ],
        timeout: 3
      )
    )
    bilibili.tap()
    let save = app.buttons["live.settings.save"]
    XCTAssertTrue(save.waitForExistence(timeout: 3))
    save.tap()
    let saveDisabled = expectation(
      for: NSPredicate(format: "enabled == false"),
      evaluatedWith: save
    )
    await fulfillment(of: [saveDisabled], timeout: 5)
    XCTAssertFalse(save.isEnabled)
    app.tabBars.buttons["Home"].tap()
    XCTAssertTrue(
      element(in: app, labelled: "BiliBili recommendation")
        .waitForExistence(timeout: 10)
    )
    capture(app, named: "Live home · BiliBili service")
  }

  func testNicoVideoExposesNativeDanmakuControls() throws {
    server = LiveFixtureServer(prefersNicoRecommendation: true)
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    let guest = app.buttons["live.auth.guest"]
    XCTAssertTrue(guest.waitForExistence(timeout: 3))
    guest.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.authenticated.shell"]
        .waitForExistence(timeout: 10)
    )
    let nico = app.buttons["live.home.video.card.nico-1"]
    XCTAssertTrue(nico.waitForExistence(timeout: 15))
    XCTAssertTrue(nico.isHittable)
    nico.tap()

    let playerSurface = app.descendants(matching: .any)[
      "live.player.surface"
    ]
    let sponsorBlock = app.descendants(matching: .any)[
      "live.player.sponsorblock"
    ].firstMatch
    XCTAssertTrue(sponsorBlock.waitForExistence(timeout: 5))
    let sponsorTitle = app.staticTexts["Exclusive access"]
    XCTAssertTrue(sponsorTitle.waitForExistence(timeout: 3))
    XCTAssertGreaterThan(sponsorTitle.frame.width, 1)
    let skipSponsor = app.buttons["Skip"]
    XCTAssertTrue(skipSponsor.exists)
    XCTAssertGreaterThanOrEqual(
      sponsorTitle.frame.minX,
      playerSurface.frame.minX
    )
    XCTAssertLessThanOrEqual(
      skipSponsor.frame.maxX,
      playerSurface.frame.maxX
    )
    XCTAssertEqual(
      sponsorBlock.frame.midX,
      playerSurface.frame.midX,
      accuracy: 6,
      "SponsorBlock must remain centered in the inline portrait player."
    )
    capture(app, named: "Live player · SponsorBlock overlay")
    playerSurface.tap()
    let fullscreen = app.buttons.matching(
      NSPredicate(
        format: "label CONTAINS[c] %@",
        "full screen"
      )
    ).firstMatch
    XCTAssertTrue(fullscreen.waitForExistence(timeout: 3))
    fullscreen.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.player.sponsorblock"]
        .waitForExistence(timeout: 3)
    )
    capture(app, named: "Live player · Native full screen")
    app.coordinate(
      withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
    ).tap()
    capture(app, named: "Live player · Native controls revealed")
    let exitFullscreen = app.buttons["Close"]
    XCTAssertTrue(exitFullscreen.waitForExistence(timeout: 3))
    exitFullscreen.tap()
    let metadata = app.scrollViews["live.video.metadata"]
    XCTAssertTrue(metadata.waitForExistence(timeout: 3))
    let danmaku = app.descendants(matching: .any)[
      "live.danmaku.quick-action"
    ]
    for _ in 0..<6 where !danmaku.isHittable {
      metadata.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(danmaku.waitForExistence(timeout: 5))
    XCTAssertTrue(danmaku.isHittable)
    danmaku.tap()
    let speed = app.sliders["live.danmaku.speed"]
    XCTAssertTrue(speed.waitForExistence(timeout: 3))
    speed.adjust(toNormalizedSliderPosition: 0.75)
    let size = app.sliders["live.danmaku.size"]
    XCTAssertTrue(size.waitForExistence(timeout: 3))
    size.adjust(toNormalizedSliderPosition: 0.6)
    capture(app, named: "Live player · Danmaku quick controls")
    app.coordinate(
      withNormalizedOffset: CGVector(dx: 0.05, dy: 0.9)
    ).tap()

    XCTAssertTrue(
      app.scrollViews["live.video.metadata"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Likes")
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Dislikes").exists
    )
    XCTAssertTrue(
      element(in: app, labelled: "Share").exists
    )
    XCTAssertTrue(
      element(in: app, labelled: "Download").exists
    )
    capture(app, named: "Live player · NicoNico danmaku")
  }

  func testCaptionAppearanceInLightMode() throws {
    try auditCaptionAppearance(
      serverURL: try server.start(),
      interfaceStyle: "Light"
    )
  }

  func testCaptionAppearanceInDarkMode() throws {
    try auditCaptionAppearance(
      serverURL: try server.start(),
      interfaceStyle: "Dark"
    )
  }

  func testYouTubeImportPresentsQueueAndTakeoutGuide() throws {
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
      "-AppleInterfaceStyle",
      "Dark",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()
    let more = try XCTUnwrap(
      firstElement(
        [
          app.tabBars.buttons["More"],
          app.buttons["More"].firstMatch,
          element(in: app, labelled: "More"),
        ],
        timeout: 15
      )
    )
    XCTAssertTrue(more.isHittable)
    more.tap()

    let importData = element(in: app, labelled: "Import data")
    for _ in 0..<8 {
      if importData.exists, importData.isHittable {
        break
      }
      app.swipeUp()
    }
    XCTAssertTrue(importData.waitForExistence(timeout: 3))
    XCTAssertTrue(importData.isHittable)
    importData.tap()

    let screen = app.collectionViews["live.import.screen"]
    XCTAssertTrue(screen.waitForExistence(timeout: 5))
    XCTAssertTrue(
      element(in: app, labelled: "Add Takeout archives").exists
    )
    XCTAssertTrue(
      element(in: app, labelled: "No archives queued").exists
    )
    let guide = element(
      in: app,
      labelled: "How to export from YouTube"
    )
    XCTAssertTrue(guide.waitForExistence(timeout: 3))
    guide.tap()
    XCTAssertTrue(
      element(in: app, labelled: "Open Google Takeout")
        .waitForExistence(timeout: 3)
    )
    capture(app, named: "Live import · YouTube Takeout queue")
    app.terminate()
  }

  func testDownloadContinuesAfterSheetClosesAndAppearsOffline()
    throws
  {
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()
    let card = app.buttons["live.home.video.card.video-1"]
    XCTAssertTrue(card.waitForExistence(timeout: 15))
    card.tap()

    let metadata = app.scrollViews["live.video.metadata"]
    XCTAssertTrue(metadata.waitForExistence(timeout: 5))
    let download = element(in: app, labelled: "Download")
    for _ in 0..<6 where !download.isHittable {
      metadata.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(download.isHittable)
    download.tap()

    let downloadSheet = app.descendants(matching: .any)[
      "live.download.sheet"
    ]
    XCTAssertTrue(downloadSheet.waitForExistence(timeout: 3))
    let start = app.buttons["Start download"]
    for _ in 0..<3 where !start.exists {
      downloadSheet.swipeUp()
    }
    XCTAssertTrue(start.waitForExistence(timeout: 3))
    start.tap()
    app.buttons["Close"].tap()

    app.navigationBars["Video"].buttons.firstMatch.tap()
    let more = try XCTUnwrap(
      firstElement(
        [
          app.tabBars.buttons["More"],
          app.buttons["More"].firstMatch,
          element(in: app, labelled: "More"),
        ],
        timeout: 5
      )
    )
    more.tap()
    let downloads = element(in: app, labelled: "Downloads")
    XCTAssertTrue(downloads.waitForExistence(timeout: 3))
    downloads.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["live.downloads.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Ready offline")
        .waitForExistence(timeout: 30)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Watch").exists
    )
    capture(app, named: "Live downloads · Persisted offline file")

    element(in: app, labelled: "Watch").tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.offline-player"]
        .waitForExistence(timeout: 10)
    )
    capture(app, named: "Live downloads · Local video playback")
    app.terminate()

    server.stop()
    app.launchArguments = ["--typetype-live-ui"]
    app.launch()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.connectivity.banner"]
        .waitForExistence(timeout: 15)
    )
    element(in: app, labelled: "Downloads").tap()
    XCTAssertTrue(
      element(in: app, labelled: "Ready offline")
        .waitForExistence(timeout: 5)
    )
    element(in: app, labelled: "Watch").tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.offline-player"]
        .waitForExistence(timeout: 5)
    )
    capture(app, named: "Live downloads · Playback after offline restart")
    app.terminate()
  }

  func testDownloadedAudioUsesDedicatedOfflinePlayer() throws {
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()
    let card = app.buttons["live.home.video.card.video-1"]
    XCTAssertTrue(card.waitForExistence(timeout: 15))
    card.tap()

    let metadata = app.scrollViews["live.video.metadata"]
    XCTAssertTrue(metadata.waitForExistence(timeout: 5))
    let download = element(in: app, labelled: "Download")
    for _ in 0..<6 where !download.isHittable {
      metadata.swipeUp(velocity: .slow)
    }
    download.tap()

    let typePicker = app.buttons.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Type")
    ).firstMatch
    XCTAssertTrue(typePicker.waitForExistence(timeout: 3))
    typePicker.tap()
    let audio = element(in: app, labelled: "Audio")
    XCTAssertTrue(audio.waitForExistence(timeout: 3))
    audio.tap()

    let start = app.buttons["Start download"]
    let downloadSheet = app.descendants(matching: .any)[
      "live.download.sheet"
    ]
    for _ in 0..<3 where !start.exists {
      downloadSheet.swipeUp()
    }
    XCTAssertTrue(start.waitForExistence(timeout: 3))
    start.tap()
    app.buttons["Close"].tap()
    app.navigationBars["Video"].buttons.firstMatch.tap()
    let more = try XCTUnwrap(
      firstElement(
        [
          app.tabBars.buttons["More"],
          app.buttons["More"].firstMatch,
          element(in: app, labelled: "More"),
        ],
        timeout: 5
      )
    )
    more.tap()
    element(in: app, labelled: "Downloads").tap()

    XCTAssertTrue(
      element(in: app, labelled: "Ready offline")
        .waitForExistence(timeout: 30)
    )
    let listen = element(in: app, labelled: "Listen")
    XCTAssertTrue(listen.exists)
    listen.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.offline-audio-player"]
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      element(in: app, labelled: "Downloaded audio").exists
    )
    capture(app, named: "Live downloads · Local audio playback")
    app.terminate()

    server.stop()
    app.launchArguments = ["--typetype-live-ui"]
    app.launch()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.connectivity.banner"]
        .waitForExistence(timeout: 15)
    )
    element(in: app, labelled: "Downloads").tap()
    XCTAssertTrue(
      element(in: app, labelled: "Ready offline")
        .waitForExistence(timeout: 5)
    )
    element(in: app, labelled: "Listen").tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.offline-audio-player"]
        .waitForExistence(timeout: 5)
    )
    capture(
      app,
      named: "Live downloads · Audio playback after offline restart"
    )
    app.terminate()
  }

  func testDiagnosticsShowsSanitizedBackendRequests() throws {
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()
    XCTAssertTrue(
      app.buttons["live.home.video.card.video-1"]
        .waitForExistence(timeout: 15)
    )
    let more = try XCTUnwrap(
      firstElement(
        [
          app.tabBars.buttons["More"],
          app.buttons["More"].firstMatch,
          element(in: app, labelled: "More"),
        ],
        timeout: 5
      )
    )
    more.tap()
    let diagnostics = element(in: app, labelled: "Diagnostics")
    XCTAssertTrue(diagnostics.waitForExistence(timeout: 3))
    diagnostics.tap()

    XCTAssertTrue(
      app.collectionViews["live.diagnostics.screen"]
        .waitForExistence(timeout: 5)
    )
    let recommendationRequest = app.staticTexts.matching(
      NSPredicate(
        format: "label CONTAINS %@",
        "GET /recommendations/home"
      )
    ).firstMatch
    XCTAssertTrue(
      recommendationRequest.waitForExistence(timeout: 5)
    )
    XCTAssertTrue(element(in: app, labelled: "Share diagnostics").exists)
    capture(app, named: "Live diagnostics · Sanitized requests")
    app.terminate()
  }

  private func auditCaptionAppearance(
    serverURL: URL,
    interfaceStyle: String
  ) throws {
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    if interfaceStyle == "Light" {
      app.launchArguments.append("--typetype-force-light-appearance")
    } else {
      app.launchArguments.append(contentsOf: [
        "-AppleInterfaceStyle",
        "Dark",
      ])
    }
    app.launch()
    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()
    let more = app.tabBars.buttons["More"]
    XCTAssertTrue(more.waitForExistence(timeout: 15))
    more.tap()
    let settings = element(in: app, labelled: "Settings")
    XCTAssertTrue(settings.waitForExistence(timeout: 3))
    settings.tap()
    let settingsScreen = app.collectionViews["live.settings.screen"]
    XCTAssertTrue(settingsScreen.waitForExistence(timeout: 5))
    let appearance = element(in: app, labelled: "Caption appearance")
    for _ in 0..<2 where !appearance.isHittable {
      settingsScreen.swipeUp()
    }
    XCTAssertTrue(appearance.isHittable)
    appearance.tap()
    let appearanceScreen = app.collectionViews[
      "live.settings.caption-appearance"
    ]
    XCTAssertTrue(appearanceScreen.waitForExistence(timeout: 5))
    XCTAssertTrue(element(in: app, labelled: "Font").exists)
    XCTAssertTrue(element(in: app, labelled: "Size").exists)
    XCTAssertTrue(element(in: app, labelled: "Edge style").exists)
    capture(
      app,
      named: "Live settings · Captions · \(interfaceStyle)"
    )
    app.terminate()
  }

  private func connect(
    _ app: XCUIApplication,
    address: String
  ) {
    let name = app.textFields["live.server.name"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("Local fixture")
    let url = app.textFields["live.server.url"]
    url.tap()
    url.typeText(address)
    app.swipeUp()
    let connect = app.buttons["live.server.connect"]
    XCTAssertTrue(connect.waitForExistence(timeout: 3))
    connect.tap()
    XCTAssertTrue(
      app.buttons["live.auth.guest"]
        .waitForExistence(timeout: 10)
    )
  }

  private func capture(_ app: XCUIApplication, named name: String) {
    let attachment = XCTAttachment(
      screenshot: XCUIScreen.main.screenshot()
    )
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func element(
    in app: XCUIApplication,
    labelled label: String
  ) -> XCUIElement {
    app.descendants(matching: .any)
      .matching(NSPredicate(format: "label == %@", label))
      .firstMatch
  }

  private func firstElement(
    _ candidates: [XCUIElement],
    timeout: TimeInterval
  ) -> XCUIElement? {
    let deadline = Date().addingTimeInterval(timeout)
    repeat {
      if let element = candidates.first(where: \.exists) {
        return element
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    } while Date() < deadline
    return nil
  }
}
