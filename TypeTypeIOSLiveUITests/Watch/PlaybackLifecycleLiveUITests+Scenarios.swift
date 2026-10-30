import XCTest

@MainActor
extension PlaybackLifecycleLiveUITests {
  func testVideoMetadataUsesCompactDescriptionAndChannelStats() {
    let query = randomQuery(offset: 2)
    let app = launchConnectedApp(resetState: true)
    let videoID = playFirstResult(in: app, query: query)
    let metadata = app.scrollViews["live.video.metadata"]
    let statistics = app.descendants(matching: .any)[
      "live.video.statistics"
    ]
    XCTAssertTrue(statistics.waitForExistence(timeout: 20))
    XCTAssertTrue(
      statistics.label.localizedCaseInsensitiveContains("views")
    )
    XCTAssertNil(
      statistics.label.range(
        of: #"\b\d+:\d{2}\b"#,
        options: .regularExpression
      ),
      "Video duration must remain in the player, not the metadata."
    )

    let subscribers = app.staticTexts[
      "live.video.channel.subscribers"
    ]
    XCTAssertTrue(subscribers.waitForExistence(timeout: 20))
    XCTAssertTrue(
      subscribers.label.localizedCaseInsensitiveContains(
        "subscribers"
      )
    )

    let toggle = app.buttons["live.video.description.toggle"]
    for _ in 0..<4 where !toggle.isHittable {
      metadata.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(toggle.waitForExistence(timeout: 10))
    XCTAssertEqual(toggle.label, "Description")
    let published = app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "Published ")
    ).firstMatch
    XCTAssertFalse(
      published.exists,
      "The description tile must be closed by default."
    )
    attach(
      app,
      name: "Compact video description",
      details: "query=\(query)\nvideo=\(videoID)"
    )

    toggle.tap()
    XCTAssertTrue(published.waitForExistence(timeout: 5))
    attach(
      app,
      name: "Expanded video description",
      details: "query=\(query)\nvideo=\(videoID)"
    )

    toggle.tap()
    XCTAssertFalse(
      published.exists,
      "The second tap must collapse the description again."
    )
  }

  func testRandomizedAudioOnlyVideoRoundTrip() {
    let query = randomQuery(offset: 0)
    let app = launchConnectedApp(resetState: true)
    let videoID = playFirstResult(in: app, query: query)

    setAudioOnly(true, in: app)
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 120))
    let audioOnlyEnd = assertPlaybackAdvances(
      in: app,
      seconds: 12
    )
    verifyAudioOnly(true, in: app)

    setAudioOnly(false, in: app)
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 120))
    let videoEnd = assertPlaybackAdvances(
      in: app,
      seconds: 12
    )
    XCTAssertGreaterThan(
      videoEnd,
      audioOnlyEnd,
      "Returning to video lost or stalled the playback timeline."
    )
    verifyAudioOnly(false, in: app)
    attach(
      app,
      name: "Audio-only to video",
      details: "query=\(query)\nvideo=\(videoID)"
    )
  }

  func testProcessRelaunchKeepsLiveSessionUsable() {
    let queries = randomQueries(count: 2)
    let firstQuery = queries[0]
    let secondQuery = queries[1]
    let app = launchConnectedApp(resetState: true)
    let firstID = playFirstResult(in: app, query: firstQuery)
    _ = assertPlaybackAdvances(in: app, seconds: 15)
    app.terminate()

    app.launchArguments = ["--typetype-live-ui"]
    app.launch()
    XCTAssertTrue(
      app.otherElements["live.home.screen"]
        .waitForExistence(timeout: 30),
      "The persisted live session did not survive process relaunch."
    )
    XCTAssertFalse(app.buttons["live.auth.guest"].exists)
    let secondID = playFirstResult(in: app, query: secondQuery)
    XCTAssertNotEqual(firstID, secondID)
    _ = assertPlaybackAdvances(in: app, seconds: 15)
    XCTAssertTrue(waitForPlayingPlayer(in: app, timeout: 30))
    attach(
      app,
      name: "Playback after process relaunch",
      details: """
      firstQuery=\(firstQuery)
      firstVideo=\(firstID)
      secondQuery=\(secondQuery)
      secondVideo=\(secondID)
      """
    )
  }
}
