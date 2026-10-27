import XCTest

@MainActor
final class LiveAppearanceUITests: XCTestCase {
  private var server: LiveFixtureServer!

  override func setUpWithError() throws {
    continueAfterFailure = false
    server = LiveFixtureServer()
  }

  override func tearDown() {
    server?.stop()
    server = nil
    super.tearDown()
  }

  func testAppearanceControlsUpdatePreviewAndCaptureScreenshots() throws {
    let serverURL = try server.start()
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: serverURL.absoluteString)
    app.buttons["live.auth.guest"].tap()

    let more = firstElement(
      [
        app.buttons["live.home.settings"],
      ],
      timeout: 15
    )
    let moreButton = try XCTUnwrap(more)
    moreButton.tap()

    let settingsScreen = app.collectionViews["live.settings.screen"]
    _ = settingsScreen.waitForExistence(timeout: 5)

    let appearanceButton = try XCTUnwrap(firstElement(
      [
        element(in: app, labelled: "Appearance"),
        element(in: app, labelled: "Apparence"),
      ],
      timeout: 5
    ))
    appearanceButton.tap()

    let preview = app.staticTexts["live.settings.appearance.preview"]
    _ = preview.waitForExistence(timeout: 5)
    capture(app, named: "Appearance · Initial")

    try selectMenuOption("Manga", in: app, pickerLabel: "Personality")
    XCTAssertTrue(
      element(in: app, labelled: "Screentone").waitForExistence(timeout: 3)
    )

    try selectMenuOption("Nord", in: app, pickerLabel: "Theme")
    capture(app, named: "Appearance · Manga Nord")

    try selectMenuOption("Blue", in: app, pickerLabel: "Accent color")
    XCTAssertTrue(
      element(in: app, labelled: "Blue").waitForExistence(timeout: 3)
    )
    capture(app, named: "Appearance · Blue accent")

    app.swipeDown()
    capture(app, named: "Appearance · Final")
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
      app.buttons["live.auth.guest"].waitForExistence(timeout: 10)
    )
  }

  private func selectMenuOption(
    _ title: String,
    in app: XCUIApplication,
    pickerLabel: String
  ) throws {
    let picker = firstElement(
      [
        app.buttons.matching(
          NSPredicate(format: "label BEGINSWITH %@", pickerLabel)
        ).firstMatch,
        app.otherElements.matching(
          NSPredicate(format: "label BEGINSWITH %@", pickerLabel)
        ).firstMatch,
      ],
      timeout: 3
    )
    let pickerButton = try XCTUnwrap(picker)
    pickerButton.tap()

    let option = firstElement(
      [
        app.buttons[title],
        app.staticTexts[title],
        element(in: app, labelled: title),
      ],
      timeout: 3
    )
    let optionButton = try XCTUnwrap(option)
    optionButton.tap()
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
