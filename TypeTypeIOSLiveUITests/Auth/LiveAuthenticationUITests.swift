import XCTest

@MainActor
final class LiveAuthenticationUITests: XCTestCase {
  func testConfiguredInstanceExposesCurrentAuthenticationOptions() async throws {
    let environment = ProcessInfo.processInfo.environment
    guard
      let liveURL = environment["TYPETYPE_UI_TEST_LIVE_URL"]
        ?? environment["TYPETYPE_UI_TEST_PRODUCTION_URL"],
      !liveURL.isEmpty
    else {
      throw XCTSkip(
        "TYPETYPE_UI_TEST_LIVE_URL is not configured"
      )
    }
    let capabilities = try await fetchCapabilities(
      liveURL: liveURL
    )
    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(
      app,
      name: "TypeType",
      address: liveURL
    )
    assertAuthenticationSurface(in: app, capabilities: capabilities)
    capture(app, named: "Live authentication · HTTPS instance")
    assertLightAppearance(in: app)
    if capabilities.guestAllowed {
      exerciseGuestSession(in: app)
    }
  }

  private func connect(
    _ app: XCUIApplication,
    name: String,
    address: String
  ) {
    let nameField = app.textFields["live.server.name"]
    XCTAssertTrue(nameField.waitForExistence(timeout: 5))
    nameField.tap()
    nameField.typeText(name)

    let addressField = app.textFields["live.server.url"]
    addressField.tap()
    addressField.typeText(address)
    app.swipeUp()
    let connect = app.buttons["live.server.connect"]
    XCTAssertTrue(connect.waitForExistence(timeout: 2))
    XCTAssertTrue(connect.isHittable)
    connect.tap()

    XCTAssertTrue(
      app.buttons["live.auth.submit"].waitForExistence(timeout: 15)
    )
  }

  private func assertAuthenticationSurface(
    in app: XCUIApplication,
    capabilities: ProductionCapabilities
  ) {
    XCTAssertTrue(app.textFields["Email or username"].exists)
    XCTAssertTrue(app.secureTextFields["Password"].exists)
    XCTAssertEqual(
      app.buttons["live.auth.guest"].exists,
      capabilities.guestAllowed
    )
    XCTAssertEqual(
      app.buttons["live.auth.oidc"].exists,
      capabilities.oidcEnabled
    )

    let register = app.buttons["Create account"]
    XCTAssertTrue(register.waitForExistence(timeout: 5))
    register.tap()
    XCTAssertTrue(app.textFields["Name"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.textFields["Email"].exists)
    XCTAssertFalse(app.buttons["live.auth.submit"].isEnabled)
    app.buttons["Already registered? Sign in"].tap()
    XCTAssertTrue(
      app.textFields["Email or username"].waitForExistence(timeout: 2)
    )
  }

  private func fetchCapabilities(
    liveURL: String
  ) async throws -> ProductionCapabilities {
    let baseURL = try XCTUnwrap(URL(string: liveURL))
    let candidates = [
      baseURL.appending(path: "api").appending(path: "instance"),
      baseURL.appending(path: "instance"),
    ]
    for url in candidates {
      guard let (data, response) = try? await URLSession.shared.data(
        from: url
      ), (response as? HTTPURLResponse)?.statusCode == 200 else {
        continue
      }
      return try JSONDecoder().decode(
        ProductionCapabilities.self,
        from: data
      )
    }
    throw ProductionCapabilityError.unavailable
  }

  private func assertLightAppearance(in app: XCUIApplication) {
    let light = app.buttons["Use light appearance"]
    XCTAssertTrue(light.waitForExistence(timeout: 2))
    light.tap()
    XCTAssertTrue(
      app.buttons["Use dark appearance"].waitForExistence(timeout: 2)
    )
    XCTAssertTrue(app.textFields["Email or username"].exists)
    capture(app, named: "Live authentication · Light appearance")
    app.buttons["Use dark appearance"].tap()
  }

  private func exerciseGuestSession(in app: XCUIApplication) {
    app.buttons["live.auth.guest"].tap()
    XCTAssertTrue(
      app.otherElements["live.home.screen"].waitForExistence(timeout: 15)
    )
    XCTAssertTrue(
      app.staticTexts["No recommendations yet"]
        .waitForExistence(timeout: 15)
    )
    exerciseProductionSearch(in: app)
    tapMoreTab(in: app)
    let signOut = app.buttons["live.account.sign-out"]
    for _ in 0..<8 where !signOut.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(signOut.isHittable)
    signOut.tap()
    XCTAssertTrue(
      app.buttons["live.auth.submit"].waitForExistence(timeout: 5)
    )
  }

  private func exerciseProductionSearch(
    in app: XCUIApplication
  ) {
    let search = app.searchTabButton
    XCTAssertTrue(search.waitForExistence(timeout: 3))
    search.tap()
    let field = app.searchFields[
      "Search videos, channels..."
    ]
    XCTAssertTrue(field.waitForExistence(timeout: 3))
    field.tap()
    field.typeText("Big Buck Bunny")
    app.keyboards.buttons["Search"].tap()
    XCTAssertTrue(
      app.buttons.matching(
        NSPredicate(
          format: "identifier BEGINSWITH %@",
          "live.home.video.card."
        )
      ).firstMatch.waitForExistence(timeout: 90)
    )
    capture(app, named: "Live search · HTTPS instance")
    app.tabBars.buttons["Home"].tap()
    XCTAssertTrue(
      app.otherElements["live.search.screen"]
        .waitForNonExistence(timeout: 5)
    )
  }

  private func tapMoreTab(in app: XCUIApplication) {
    let candidates = app.buttons.matching(
      identifier: "line.3.horizontal"
    )
    for index in 0..<candidates.count {
      let candidate = candidates.element(boundBy: index)
      if candidate.label == "More" && candidate.isHittable {
        candidate.tap()
        return
      }
    }
    let tabButton = app.buttons["live.home.settings"]
    XCTAssertTrue(tabButton.waitForExistence(timeout: 2))
    tabButton.tap()
  }

  private func capture(_ app: XCUIApplication, named name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}

private struct ProductionCapabilities: Decodable {
  let guestAllowed: Bool
  let oidcEnabled: Bool
}

private enum ProductionCapabilityError: Error {
  case unavailable
}
