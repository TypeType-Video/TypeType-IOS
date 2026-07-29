import XCTest

@MainActor
extension PlaybackMatrixLiveUITests {
  func startMatrixDownload(
    mode: String,
    quality: String?,
    in app: XCUIApplication
  ) throws {
    let metadata = app.scrollViews["live.video.metadata"]
    XCTAssertTrue(metadata.waitForExistence(timeout: 10))
    let download = matrixElement(labelled: "Download", in: app)
    for _ in 0..<8 where !download.isHittable {
      metadata.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(download.isHittable)
    download.tap()

    let sheet = app.descendants(matching: .any)[
      "live.download.sheet"
    ]
    XCTAssertTrue(sheet.waitForExistence(timeout: 5))
    if mode == "Audio" {
      let type = app.buttons["live.download.type"]
      XCTAssertTrue(type.waitForExistence(timeout: 5))
      type.tap()
      let audio = app.buttons["Audio"]
      XCTAssertTrue(audio.waitForExistence(timeout: 5))
      audio.tap()
      let deadline = Date().addingTimeInterval(5)
      while Date() < deadline,
        !type.label.localizedCaseInsensitiveContains("Audio") {
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
      }
      XCTAssertTrue(
        type.label.localizedCaseInsensitiveContains("Audio"),
        "The download type did not switch to audio."
      )
    }
    if let quality {
      let picker = app.buttons["live.download.quality"]
      XCTAssertTrue(picker.waitForExistence(timeout: 5))
      picker.tap()
      let option = matrixElement(labelled: quality, in: app)
      XCTAssertTrue(option.waitForExistence(timeout: 5))
      option.tap()
    }

    let start = app.buttons["Start download"]
    for _ in 0..<4 where !start.isHittable {
      sheet.swipeUp()
    }
    XCTAssertTrue(start.waitForExistence(timeout: 5))
    XCTAssertTrue(start.isHittable)
    start.tap()
    let ready = matrixElement(labelled: "Open or save file", in: app)
    let failure = matrixElement(labelled: "Download failed", in: app)
    let deadline = Date().addingTimeInterval(600)
    while Date() < deadline, !ready.exists, !failure.exists {
      RunLoop.current.run(until: Date().addingTimeInterval(1))
    }
    if failure.exists {
      XCTFail("The real backend rejected the download.")
      throw NSError(
        domain: "PlaybackMatrixLiveUITests.Download",
        code: 1
      )
    }
    guard ready.exists else {
      XCTFail("The real backend download did not produce a local artifact.")
      throw NSError(
        domain: "PlaybackMatrixLiveUITests.Download",
        code: 2
      )
    }
    let closeDownload = app.navigationBars["Download"].buttons["Close"]
    XCTAssertTrue(closeDownload.waitForExistence(timeout: 10))
    closeDownload.tap()
    XCTAssertTrue(sheet.waitForNonExistence(timeout: 10))
  }

  func openMatrixDownloads(in app: XCUIApplication) throws {
    app.terminate()
    app.launchArguments = [
      "--typetype-live-ui",
      "--typetype-open-downloads",
    ]
    app.launch()
    XCTAssertTrue(
      app.descendants(matching: .any)["live.downloads.screen"]
        .waitForExistence(timeout: 30)
    )
  }

  func assertMatrixDownloadReadyAndPlayable(
    action: String,
    playerIdentifier: String,
    in app: XCUIApplication
  ) throws {
    let ready = matrixElement(labelled: "Ready offline", in: app)
    XCTAssertTrue(
      ready.waitForExistence(timeout: 600),
      "The real backend download did not become ready."
    )
    let play = matrixElement(labelled: action, in: app)
    XCTAssertTrue(play.waitForExistence(timeout: 10))
    play.tap()
    XCTAssertTrue(
      app.descendants(matching: .any)[playerIdentifier]
        .waitForExistence(timeout: 15)
    )
    RunLoop.current.run(until: Date().addingTimeInterval(10))
    XCTAssertFalse(
      matrixElement(labelled: "Playback unavailable", in: app).exists
    )
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Real \(action.lowercased()) download playback"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    app.terminate()
  }
}
