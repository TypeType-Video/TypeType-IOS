import XCTest

final class ParityMutationsUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
  }

  func testChannelPodcastOpensItsOwnCatalog() {
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let channel = app.buttons["demo.watch.channel"]
    reveal(channel)
    channel.tap()

    let podcast = app.buttons[
      "demo.channel.podcast.blender-creator-systems"
    ]
    XCTAssertTrue(podcast.waitForExistence(timeout: 3))
    podcast.tap()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.podcasts.screen"]
        .waitForExistence(timeout: 3)
    )
    XCTAssertTrue(app.staticTexts["Creator Systems"].exists)
    XCTAssertTrue(app.staticTexts["Blender Open Movies"].exists)
    XCTAssertTrue(
      app.staticTexts["12 mock episodes from this channel."].exists
    )

    let capture = XCTAttachment(screenshot: app.screenshot())
    capture.name = "Channel-specific podcast catalog"
    capture.lifetime = .keepAlways
    add(capture)
  }

  func testProfileMutationIsSharedWithMoreCard() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.buttons["demo.more.profile"].tap()
    let username = app.textFields["Public username"]
    XCTAssertTrue(username.waitForExistence(timeout: 3))
    username.tap()
    username.typeText("-ios")
    app.buttons["demo.profile.save"].tap()

    XCTAssertTrue(
      app.staticTexts["Profile saved for this session."].waitForExistence(
        timeout: 3
      )
    )
    app.buttons["Close"].tap()
    XCTAssertTrue(
      app.staticTexts["@typetype-ios · TypeType Beta"].waitForExistence(
        timeout: 3
      )
    )
  }

  func testPipePipeImportMutatesTheLibrary() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.staticTexts["Import"].tap()
    app.buttons["demo.import.source.pipePipe"].tap()
    let sample = app.buttons["Use sample archive"]
    XCTAssertTrue(sample.waitForExistence(timeout: 3))
    sample.tap()
    XCTAssertTrue(
      app.staticTexts["Import complete"].waitForExistence(timeout: 4)
    )
    app.buttons["Done"].tap()

    app.tapTab("Playlists")
    let imported = app.staticTexts["Imported from PipePipe"]
    reveal(imported)
    XCTAssertTrue(imported.exists)
  }

  func testDownloadsResumeAndClearLocally() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    app.staticTexts["Downloads"].tap()
    XCTAssertTrue(
      app.staticTexts["2 ready offline"].waitForExistence(timeout: 3)
    )
    app.buttons["Download actions"].tap()
    app.buttons["Resume all"].tap()
    XCTAssertTrue(
      app.staticTexts["4 ready offline"].waitForExistence(timeout: 3)
    )

    app.buttons["Download actions"].tap()
    app.buttons["Clear completed"].tap()
    XCTAssertTrue(
      app.staticTexts["0 ready offline"].waitForExistence(timeout: 3)
    )
  }

  func testHideEverythingMutatesEveryDiscoverySurface() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    let discovery = app.staticTexts["Discovery & services"]
    reveal(discovery)
    discovery.tap()
    let start = app.buttons["demo.hide-everything.start"]
    reveal(start)
    start.tap()

    tapAlertButton("Yeah, hide it")
    tapAlertButton("I am sure")
    tapAlertButton("Yes, gone")
    tapAlertButton("Fine, hide it")

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.hide-everything.scene"]
        .waitForExistence(timeout: 3)
    )
    app.buttons["Leave zen scene"].tap()
    app.tapTab("Home")
    XCTAssertTrue(app.staticTexts["Home is quiet"].waitForExistence(timeout: 3))
    XCTAssertFalse(app.staticTexts["Continue watching"].exists)
    XCTAssertFalse(app.staticTexts["Recommended"].exists)
  }

  func testBugReportAppearsInAdminIssues() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    let report = app.staticTexts["Report a problem"]
    reveal(report)
    report.tap()
    let detail = app.textFields["What happened?"]
    XCTAssertTrue(detail.waitForExistence(timeout: 3))
    detail.tap()
    detail.typeText("Mock parity issue")
    app.buttons["Save report locally"].tap()
    XCTAssertTrue(
      app.staticTexts[
        "Mock report saved and visible in Admin → Issues."
      ].waitForExistence(timeout: 3)
    )

    app.swipeDown()
    let backButton = app.navigationBars["Report a problem"].buttons.firstMatch
    XCTAssertTrue(backButton.waitForExistence(timeout: 3))
    XCTAssertTrue(backButton.isHittable)
    backButton.tap()
    let admin = app.staticTexts["Admin console"]
    reveal(admin)
    admin.tap()
    app.buttons["Issues"].tap()
    XCTAssertTrue(
      app.staticTexts["Playback report from iOS"].waitForExistence(
        timeout: 3
      )
    )
  }

  func testClearingHistoryAlsoRemovesContinueWatching() {
    app.launchArguments = ["--typetype-demo-more"]
    app.launch()

    let privacy = app.staticTexts["Privacy"]
    reveal(privacy)
    privacy.tap()
    let clear = app.buttons["demo.privacy.clear.history"]
    XCTAssertTrue(clear.waitForExistence(timeout: 3))
    clear.tap()
    app.sheets.buttons["Clear"].tap()

    app.tapTab("Home")
    XCTAssertFalse(app.staticTexts["Continue watching"].exists)
    XCTAssertTrue(app.staticTexts["Recommended"].waitForExistence(timeout: 3))
  }

  func testLandingPreferenceOpensWatchLaterAfterSignIn() {
    app.launchArguments = ["--typetype-demo-auth"]
    app.launch()
    signIn()
    let more = app.tabItem("More")
    XCTAssertTrue(more.waitForExistence(timeout: 3))
    more.tap()
    let moreScreen = app.descendants(matching: .any)["demo.more.screen"]
    if !moreScreen.waitForExistence(timeout: 2) {
      more.tap()
    }
    XCTAssertTrue(moreScreen.waitForExistence(timeout: 4))

    let discovery = app.staticTexts["Discovery & services"]
    reveal(discovery)
    discovery.tap()
    let landing = app.buttons.matching(
      NSPredicate(format: "label CONTAINS %@", "Default landing page")
    ).firstMatch
    XCTAssertTrue(landing.waitForExistence(timeout: 3))
    landing.tap()
    app.buttons["Watch later"].tap()
    if app.navigationBars["Default landing page"].exists {
      app.navigationBars["Default landing page"].buttons.firstMatch.tap()
    }
    app.navigationBars["Discovery & services"].buttons.firstMatch.tap()

    let signOut = app.buttons["Sign out"]
    reveal(signOut)
    signOut.tap()
    signIn()

    XCTAssertTrue(
      app.descendants(matching: .any)["demo.playlist-detail.screen"]
        .waitForExistence(timeout: 4)
    )
    XCTAssertTrue(app.navigationBars["Watch later"].exists)
  }

  private func signIn() {
    let email = app.textFields["Email or username"]
    XCTAssertTrue(email.waitForExistence(timeout: 3))
    email.tap()
    email.typeText("demo@typetype.video")
    let password = app.secureTextFields["Password"]
    password.tap()
    password.typeText("typetype")
    app.buttons["demo.auth.submit"].tap()
    dismissCredentialSavePromptIfNeeded()
    XCTAssertTrue(app.tabItem("Home").waitForExistence(timeout: 4))
  }

  private func dismissCredentialSavePromptIfNeeded() {
    for label in ["Not Now", "Plus tard"] {
      let button = app.buttons[label]
      if button.waitForExistence(timeout: 1) {
        button.tap()
        return
      }
    }
  }

  private func tapAlertButton(_ label: String) {
    let button = app.alerts.firstMatch.buttons[label]
    XCTAssertTrue(button.waitForExistence(timeout: 3))
    button.tap()
  }

  private func reveal(_ element: XCUIElement) {
    for _ in 0..<8 where !element.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(element.waitForExistence(timeout: 3))
    XCTAssertTrue(element.isHittable)
  }
}
