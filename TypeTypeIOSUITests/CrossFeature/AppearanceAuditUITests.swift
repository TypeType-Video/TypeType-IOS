import XCTest

final class AppearanceAuditUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  func testEveryPrimarySurfaceSupportsDarkAndLightAppearance() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()
    selectAppearance(named: "Dark")
    capturePrimarySurfaces(named: "Dark")
    selectAppearance(named: "Light")
    capturePrimarySurfaces(named: "Light")
  }

  func testAuthenticationSupportsDarkAndLightAppearance() {
    app.launchArguments = ["--typetype-demo-auth"]
    app.launch()
    XCTAssertTrue(
      app.textFields["Email or username"].waitForExistence(timeout: 3)
    )
    capture(named: "Dark appearance · Authentication")

    let light = app.buttons["Use light appearance"]
    XCTAssertTrue(light.waitForExistence(timeout: 3))
    light.tap()
    XCTAssertTrue(app.buttons["Use dark appearance"].waitForExistence(timeout: 2))
    capture(named: "Light appearance · Authentication")
  }

  private func capturePrimarySurfaces(named appearance: String) {
    let surfaces = [
      ("Home", "demo.home.brand"),
      ("Subscriptions", "demo.subscriptions.screen"),
      ("History", "demo.history.screen"),
      ("Playlists", "demo.playlists.screen"),
      ("More", "demo.more.screen"),
    ]

    for (tab, identifier) in surfaces {
      app.tapTab(tab)
      XCTAssertTrue(
        app.descendants(matching: .any)[identifier]
          .waitForExistence(timeout: 3)
      )
      capture(named: "\(appearance) appearance · \(tab)")
    }
  }

  private func selectAppearance(named appearanceName: String) {
    app.tapTab("More")
    let appearance = app.staticTexts["Appearance"]
    XCTAssertTrue(appearance.waitForExistence(timeout: 3))
    appearance.tap()

    let scheme = app.buttons.matching(
      NSPredicate(format: "label CONTAINS %@", "Color scheme")
    ).firstMatch
    XCTAssertTrue(scheme.waitForExistence(timeout: 3))
    scheme.tap()
    let option = app.buttons[appearanceName]
    XCTAssertTrue(option.waitForExistence(timeout: 2))
    option.tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()
  }

  private func capture(named name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
