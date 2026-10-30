import XCTest

final class AuthUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  func testSignInCompletesWithoutBackend() {
    app.launchArguments = ["--typetype-demo-auth"]
    app.launch()

    let email = app.textFields["Email or username"]
    XCTAssertTrue(email.waitForExistence(timeout: 3))
    email.tap()
    email.typeText("demo@typetype.video")

    let password = app.secureTextFields["Password"]
    password.tap()
    password.typeText("typetype")

    let submit = app.buttons["demo.auth.submit"]
    XCTAssertTrue(submit.isEnabled)
    submit.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.home.brand"].waitForExistence(timeout: 3)
    )
  }

  func testRegisterAndSignInSwitchLocally() {
    app.launchArguments = ["--typetype-demo-register"]
    app.launch()

    XCTAssertTrue(
      app.staticTexts["Create account"].waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.textFields["Name"].exists)
    XCTAssertTrue(app.textFields["Email or username"].exists)

    app.buttons["Sign in"].tap()

    XCTAssertTrue(app.staticTexts["Sign in"].waitForExistence(timeout: 2))
    XCTAssertFalse(app.textFields["Name"].exists)
  }

  func testResetPasswordCompletesWithoutNetwork() {
    app.launchArguments = ["--typetype-demo-auth"]
    app.launch()

    let reset = app.buttons["Reset password"]
    XCTAssertTrue(reset.waitForExistence(timeout: 3))
    reset.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.auth.reset.screen"]
        .waitForExistence(timeout: 3)
    )
    let email = app.textFields["demo.auth.reset.email"]
    email.tap()
    email.typeText("demo@typetype.video")
    app.buttons["demo.auth.reset.submit"].tap()

    XCTAssertTrue(
      app.staticTexts[
        "Reset instructions prepared for demo@typetype.video."
      ].waitForExistence(timeout: 3)
    )
  }
}
