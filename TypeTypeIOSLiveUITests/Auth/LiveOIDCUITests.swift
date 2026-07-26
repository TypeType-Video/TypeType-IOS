import XCTest

@MainActor
final class LiveOIDCUITests: XCTestCase {
  func testAuthorizationCodeFlowAuthenticatesTheApp() throws {
    let environment = ProcessInfo.processInfo.environment
    guard let labURL = environment["TYPETYPE_OIDC_LAB_URL"],
      !labURL.isEmpty
    else {
      throw XCTSkip("TYPETYPE_OIDC_LAB_URL is not configured")
    }

    let app = XCUIApplication()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-reset-live-state",
    ]
    app.launch()

    connect(app, address: labURL)
    let oidc = app.buttons["live.auth.oidc"]
    XCTAssertTrue(oidc.waitForExistence(timeout: 10))
    XCTAssertEqual(
      oidc.label,
      "Continue with TypeType OIDC Lab"
    )
    oidc.tap()

    let browser = XCUIApplication(
      bundleIdentifier: "com.apple.SafariViewService"
    )
    let springboard = XCUIApplication(
      bundleIdentifier: "com.apple.springboard"
    )
    dismissPrivacyPrompt(
      app: app,
      browser: browser,
      springboard: springboard
    )

    let username = try XCTUnwrap(firstElement(
      [
        app.textFields.matching(
          NSPredicate(
            format: "placeholderValue == %@",
            "Enter any user/subject"
          )
        ).firstMatch,
        browser.textFields.matching(
          NSPredicate(
            format: "placeholderValue == %@",
            "Enter any user/subject"
          )
        ).firstMatch,
      ],
      timeout: 15
    ))
    username.tap()
    username.typeText("typetype-ios")

    let signIn = try XCTUnwrap(firstElement(
      [
        app.buttons["Sign-in"],
        browser.buttons["Sign-in"],
      ],
      timeout: 5
    ))
    signIn.tap()

    XCTAssertTrue(
      app.otherElements["live.authenticated.shell"]
        .waitForExistence(timeout: 20)
    )
    XCTAssertTrue(
      app.otherElements["live.home.screen"]
        .waitForExistence(timeout: 20)
    )

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Live authentication · OIDC authorization code"
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
    name.typeText("OIDC lab")

    let url = app.textFields["live.server.url"]
    url.tap()
    url.typeText(address)
    app.swipeUp()

    let connect = app.buttons["live.server.connect"]
    XCTAssertTrue(connect.waitForExistence(timeout: 3))
    connect.tap()
    XCTAssertTrue(
      app.buttons["live.auth.submit"]
        .waitForExistence(timeout: 15)
    )
  }

  private func dismissPrivacyPrompt(
    app: XCUIApplication,
    browser: XCUIApplication,
    springboard: XCUIApplication
  ) {
    let labels = ["Continue", "Continuer"]
    let predicate = NSPredicate(format: "label IN %@", labels)
    for host in [app, browser, springboard] {
      let button = host.buttons.matching(predicate).firstMatch
      if button.waitForExistence(timeout: 2) {
        button.tap()
        return
      }
    }
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
