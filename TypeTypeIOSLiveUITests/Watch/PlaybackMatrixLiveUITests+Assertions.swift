import XCTest

@MainActor
extension PlaybackMatrixLiveUITests {
  func assertMatrixPlaybackAdvances(
    in app: XCUIApplication,
    seconds: TimeInterval
  ) throws {
    let start = try matrixPlaybackPosition(in: app)
    var last = start
    var lastAdvance = Date()
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(2))
      guard waitForMatrixPlayback(in: app, timeout: 8) else {
        XCTFail("Playback remained stalled.")
        return
      }
      let current = try matrixPlaybackPosition(in: app)
      if current > last {
        last = current
        lastAdvance = Date()
      }
      guard Date().timeIntervalSince(lastAdvance) < 10 else {
        XCTFail("Timeline stopped advancing at \(current).")
        return
      }
    }
    XCTAssertGreaterThanOrEqual(
      last - start,
      max(seconds - 10, seconds * 0.65)
    )
  }

  func exerciseMatrixSeek(
    in app: XCUIApplication,
    chapterTitle: String,
    target: TimeInterval,
    sponsorSkipEnd: TimeInterval?
  ) throws {
    let metadata = app.scrollViews["live.video.metadata"]
    XCTAssertTrue(metadata.waitForExistence(timeout: 10))
    let chapterStrip = app.scrollViews["live.video.chapters"]
    for _ in 0..<8 where !chapterStrip.isHittable {
      metadata.swipeUp(velocity: .slow)
    }
    XCTAssertTrue(chapterStrip.waitForExistence(timeout: 10))
    XCTAssertTrue(chapterStrip.isHittable)
    let chapter = app.buttons[
      "live.video.chapter.\(Int(target))"
    ]
    for _ in 0..<6 where !chapter.isHittable {
      chapterStrip.swipeLeft(velocity: .slow)
    }
    XCTAssertTrue(chapter.waitForExistence(timeout: 10))
    XCTAssertTrue(chapter.isHittable)
    let started = Date()
    chapter.tap()

    let minimum = sponsorSkipEnd ?? target
    let deadline = started.addingTimeInterval(
      sponsorSkipEnd == nil ? 120 : 85
    )
    let positionElement = app.otherElements["live.player.position"]
    var position: TimeInterval = 0
    repeat {
      if let current = livePlaybackPosition(from: positionElement) {
        position = current
        if current >= minimum - 4 {
          break
        }
      }
      RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    } while Date() < deadline

    let report = XCTAttachment(
      string: """
      chapter=\(chapterTitle)
      target=\(target)
      sponsorEnd=\(sponsorSkipEnd.map { String($0) } ?? "none")
      position=\(position)
      elapsed=\(Date().timeIntervalSince(started))
      """
    )
    report.name = "Chapter seek"
    report.lifetime = .keepAlways
    add(report)
    XCTAssertGreaterThanOrEqual(
      position,
      minimum - 4,
      "Seek or SponsorBlock skip landed at \(position), expected \(minimum)."
    )
    if sponsorSkipEnd != nil {
      XCTAssertLessThan(
        Date().timeIntervalSince(started),
        sponsorSkipEnd! - target - 10,
        "Sponsor segment was not skipped ahead of natural playback."
      )
    }
  }

  func matrixPlaybackPosition(
    in app: XCUIApplication
  ) throws -> TimeInterval {
    let position = app.otherElements["live.player.position"]
    XCTAssertTrue(position.waitForExistence(timeout: 10))
    return try XCTUnwrap(
      livePlaybackPosition(from: position),
      "Playback position is not numeric."
    )
  }

  func waitForMatrixPlayback(
    in app: XCUIApplication,
    timeout: TimeInterval
  ) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    repeat {
      let player = app.otherElements["live.player.container"]
      if player.exists, player.value as? String == "playing" {
        return true
      }
      RunLoop.current.run(until: Date().addingTimeInterval(1))
    } while Date() < deadline
    return false
  }
}
