import XCTest

final class ExtendedParityUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  func testOpenIDFlowAuthorizesEntirelyLocally() {
    app.launchArguments = ["--typetype-demo-auth"]
    app.launch()

    let lightAppearance = app.buttons["Use light appearance"]
    XCTAssertTrue(lightAppearance.waitForExistence(timeout: 3))
    lightAppearance.tap()
    let openID = app.buttons["demo.auth.oidc"]
    XCTAssertTrue(openID.waitForExistence(timeout: 3))
    openID.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.oidc.screen"]
        .waitForExistence(timeout: 3)
    )
    let lightScreenshot = XCTAttachment(screenshot: app.screenshot())
    lightScreenshot.name = "Readable OpenID flow in light appearance"
    lightScreenshot.lifetime = .keepAlways
    add(lightScreenshot)
    app.buttons["demo.oidc.authorize"].tap()
    XCTAssertTrue(
      app.otherElements["demo.home.brand"].waitForExistence(timeout: 4)
    )
  }

  func testEveryAdminConsoleSectionIsReachable() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    reveal(app.staticTexts["Admin console"], direction: .up)
    app.staticTexts["Admin console"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.admin.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.switches["Allow registrations"].exists)

    app.buttons["Allow list"].tap()
    XCTAssertTrue(app.staticTexts["Global channels"].waitForExistence(timeout: 2))

    app.buttons["Users"].tap()
    XCTAssertTrue(app.searchFields["Name, email, or ID"].waitForExistence(timeout: 2))

    app.buttons["Sessions"].tap()
    XCTAssertTrue(app.staticTexts["iPhone 17 · iOS"].waitForExistence(timeout: 2))

    app.buttons["Issues"].tap()
    XCTAssertTrue(app.searchFields["Search issues"].waitForExistence(timeout: 2))
  }

  func testLightAppearanceRemainsReadableAcrossMainSurfaces() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.staticTexts["Appearance"].tap()
    let scheme = app.buttons.matching(
      NSPredicate(format: "label CONTAINS %@", "Color scheme")
    ).firstMatch
    XCTAssertTrue(scheme.waitForExistence(timeout: 3))
    scheme.tap()
    XCTAssertTrue(app.buttons["Light"].waitForExistence(timeout: 2))
    app.buttons["Light"].tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()

    app.tabBars.buttons["Subscriptions"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.subscriptions.videos"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(
      app.buttons["demo.home.video.big-buck-restored"].exists
    )

    let subscriptions = XCTAttachment(screenshot: app.screenshot())
    subscriptions.name = "Readable subscriptions in light appearance"
    subscriptions.lifetime = .keepAlways
    add(subscriptions)

    app.tabBars.buttons["More"].tap()
    app.staticTexts["Import"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.import.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.staticTexts["Import your data in minutes"].exists)
  }

  private enum ScrollDirection {
    case up
    case down
  }

  private func reveal(
    _ element: XCUIElement,
    direction: ScrollDirection
  ) {
    for _ in 0..<6 where !element.isHittable {
      if direction == .up {
        app.swipeUp()
      } else {
        app.swipeDown()
      }
    }
    XCTAssertTrue(element.waitForExistence(timeout: 2))
    XCTAssertTrue(element.isHittable)
  }
}
