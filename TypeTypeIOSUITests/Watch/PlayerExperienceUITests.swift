import XCTest

final class PlayerExperienceUITests: XCTestCase {
  func testNativeControlsAudioOnlyAndChannelNavigation() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let nativePlayer = app.descendants(matching: .any)["demo.player.surface"]
    XCTAssertTrue(nativePlayer.waitForExistence(timeout: 5))
    nativePlayer.coordinate(
      withNormalizedOffset: CGVector(dx: 0.18, dy: 0.18)
    ).tap()
    let nativeControl = app.buttons.matching(
      NSPredicate(
        format:
          "label CONTAINS[c] %@ OR label CONTAINS[c] %@ OR label CONTAINS[c] %@",
        "play",
        "screen",
        "picture"
      )
    ).firstMatch
    XCTAssertTrue(
      nativeControl.waitForExistence(timeout: 3),
      "AVPlayerViewController should expose its native transport controls."
    )
    let status = app.descendants(matching: .any)["demo.player.status"]
    let playsBeforeAudioOnly = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS %@", "Playing"),
      object: status
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [playsBeforeAudioOnly], timeout: 3),
      .completed
    )

    let audioOnly = app.buttons["Audio only"]
    let actions = app.descendants(matching: .any)["demo.watch.actions"]
    for _ in 0..<3 where !audioOnly.isHittable {
      actions.swipeLeft()
    }
    XCTAssertTrue(audioOnly.waitForExistence(timeout: 3))
    audioOnly.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.player.audio-only"]
        .waitForExistence(timeout: 3)
    )
    let continuesPlaying = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS %@", "Playing"),
      object: status
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [continuesPlaying], timeout: 3),
      .completed
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["demo.player.audio-only.artwork"]
        .waitForExistence(timeout: 2)
    )
    XCTAssertFalse(app.buttons["demo.player.audio-only.playback"].exists)
    XCTAssertFalse(app.buttons["Pause audio"].exists)
    let audioTitle = app.descendants(matching: .any)[
      "demo.player.audio-only.title"
    ]
    XCTAssertTrue(audioTitle.waitForExistence(timeout: 2))
    XCTAssertFalse(app.buttons["Back 10 seconds"].exists)
    XCTAssertFalse(app.buttons["Forward 10 seconds"].exists)
    let audioScreenshot = XCTAttachment(screenshot: app.screenshot())
    audioScreenshot.name = "Native mobile audio-only player"
    audioScreenshot.lifetime = .keepAlways
    add(audioScreenshot)

    let channel = app.buttons["demo.watch.channel"]
    XCTAssertTrue(channel.waitForExistence(timeout: 3))
    channel.tap()
    XCTAssertTrue(app.navigationBars["Channel"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["Blender Open Movies"].exists)
    let channelSearch = app.textFields["Search this channel"]
    XCTAssertTrue(channelSearch.waitForExistence(timeout: 3))
    for _ in 0..<4 where !channelSearch.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(channelSearch.isHittable)
    let channelScreenshot = XCTAttachment(screenshot: app.screenshot())
    channelScreenshot.name = "Adaptive channel search"
    channelScreenshot.lifetime = .keepAlways
    add(channelScreenshot)

    let recommendation = app.descendants(matching: .any)[
      "demo.channel.video.big-buck-bunny"
    ]
    for _ in 0..<3 where !recommendation.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(app.staticTexts["Latest videos"].exists)
    XCTAssertFalse(app.staticTexts["Recommended"].exists)
    XCTAssertTrue(recommendation.isHittable)
    XCTAssertTrue(app.staticTexts["Duration 9:56"].exists)

    let channelVideosScreenshot = XCTAttachment(screenshot: app.screenshot())
    channelVideosScreenshot.name = "Compact channel videos"
    channelVideosScreenshot.lifetime = .keepAlways
    add(channelVideosScreenshot)

    channelSearch.tap()
    channelSearch.typeText("Sintel")
    XCTAssertTrue(app.staticTexts["Search results"].waitForExistence(timeout: 2))
    XCTAssertTrue(
      app.buttons["demo.channel.video.blender-sintel"]
        .waitForExistence(timeout: 2)
    )

    app.buttons["Clear channel search"].tap()
    if app.keyboards.buttons["Search"].exists {
      app.keyboards.buttons["Search"].tap()
    }
    let sectionPicker = app.descendants(matching: .any)[
      "demo.channel.section-picker"
    ]
    for _ in 0..<4 where !sectionPicker.isHittable {
      app.swipeDown()
    }
    XCTAssertTrue(sectionPicker.waitForExistence(timeout: 2))
    XCTAssertTrue(sectionPicker.isHittable)
    app.buttons["Playlists"].tap()
    XCTAssertTrue(app.staticTexts["Open movie night"].waitForExistence(timeout: 2))

    let channelPlaylistsScreenshot = XCTAttachment(screenshot: app.screenshot())
    channelPlaylistsScreenshot.name = "Adaptive channel playlists"
    channelPlaylistsScreenshot.lifetime = .keepAlways
    add(channelPlaylistsScreenshot)

    app.buttons["Live"].tap()
    XCTAssertTrue(app.staticTexts["No live streams"].waitForExistence(timeout: 2))

    let channelContentScreenshot = XCTAttachment(screenshot: app.screenshot())
    channelContentScreenshot.name = "Native channel sections"
    channelContentScreenshot.lifetime = .keepAlways
    add(channelContentScreenshot)
  }

  func testRelatedVideosAreCompactTimedAndIncrementallyLoaded() {
    let app = XCUIApplication()
    app.launchArguments = ["--typetype-demo-player"]
    app.launch()

    let firstThumbnail = app.buttons[
      "demo.watch.related.thumbnail.native-ios"
    ]
    let finalThumbnail = app.buttons[
      "demo.watch.related.thumbnail.open-source-weekly"
    ]
    XCTAssertFalse(
      finalThumbnail.exists,
      "The final recommendation must not be built with the initial page."
    )

    for _ in 0..<14 where !firstThumbnail.isHittable {
      app.swipeUp()
    }
    XCTAssertTrue(firstThumbnail.waitForExistence(timeout: 3))
    XCTAssertTrue(firstThumbnail.isHittable)
    XCTAssertLessThanOrEqual(firstThumbnail.frame.width, 130)
    XCTAssertLessThanOrEqual(firstThumbnail.frame.height, 75)
    XCTAssertTrue(app.staticTexts["Duration 12:24"].exists)

    let compactScreenshot = XCTAttachment(screenshot: app.screenshot())
    compactScreenshot.name = "Compact incremental related videos"
    compactScreenshot.lifetime = .keepAlways
    add(compactScreenshot)

    for _ in 0..<10 where !finalThumbnail.exists {
      app.swipeUp()
    }
    XCTAssertTrue(
      finalThumbnail.waitForExistence(timeout: 3),
      "Scrolling should request subsequent recommendation pages."
    )
  }
}
