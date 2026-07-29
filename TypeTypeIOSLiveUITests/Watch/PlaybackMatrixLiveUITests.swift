import XCTest

@MainActor
final class PlaybackMatrixLiveUITests: XCTestCase {
  func testMKBHDLongPlaybackSmoke() throws {
    let scenario = LivePlaybackMatrixCase.current[0]
    let app = launchMatrixApp()
    _ = try openMatrixVideo(scenario, in: app)
    try assertMatrixPlaybackAdvances(in: app, seconds: 300)
  }

  func testGTASABRRecoverySmoke() throws {
    let scenario = LivePlaybackMatrixCase.current[1]
    let app = launchMatrixApp()
    _ = try openMatrixVideo(scenario, in: app)
    try assertMatrixPlaybackAdvances(in: app, seconds: 120)
  }

  func testYouTubeLiveLongPlaybackSmoke() throws {
    let scenario = LivePlaybackMatrixCase.current[13]
    let app = launchMatrixApp()
    _ = try openMatrixVideo(scenario, in: app)
    try assertMatrixPlaybackAdvances(in: app, seconds: 300)
  }

  func testSponsorBlockSeekSmoke() throws {
    let scenario = LivePlaybackMatrixCase.current[6]
    let app = launchMatrixApp()
    _ = try openMatrixVideo(scenario, in: app)
    try assertMatrixPlaybackAdvances(in: app, seconds: 15)
    try exerciseMatrixSeek(
      in: app,
      chapterTitle: try XCTUnwrap(scenario.chapterTitle),
      target: try XCTUnwrap(scenario.seekTarget),
      sponsorSkipEnd: try XCTUnwrap(scenario.sponsorSkipEnd)
    )
  }

  func testLongDistanceSABRSeekSmoke() throws {
    let scenario = LivePlaybackMatrixCase.current[10]
    let app = launchMatrixApp()
    _ = try openMatrixVideo(scenario, in: app)
    try assertMatrixPlaybackAdvances(in: app, seconds: 15)
    try exerciseMatrixSeek(
      in: app,
      chapterTitle: try XCTUnwrap(scenario.chapterTitle),
      target: try XCTUnwrap(scenario.seekTarget),
      sponsorSkipEnd: nil
    )
  }

  func testRealVideoDownloadPlaysOffline() throws {
    let scenario = LivePlaybackMatrixCase(
      query: "jNQXAC9IVRw",
      expectedID: "jNQXAC9IVRw",
      duration: 19,
      holdSeconds: 10
    )
    let app = launchMatrixApp()
    try selectMatrixService("YouTube", in: app)
    _ = try openMatrixVideo(scenario, in: app)
    try startMatrixDownload(
      mode: "Video",
      quality: "360P",
      in: app
    )
    try openMatrixDownloads(in: app)
    try assertMatrixDownloadReadyAndPlayable(
      action: "Watch",
      playerIdentifier: "live.offline-player",
      in: app
    )
  }

  func testRealAudioDownloadPlaysOffline() throws {
    let scenario = LivePlaybackMatrixCase(
      query: "jNQXAC9IVRw",
      expectedID: "jNQXAC9IVRw",
      duration: 19,
      holdSeconds: 10
    )
    let app = launchMatrixApp()
    try selectMatrixService("YouTube", in: app)
    _ = try openMatrixVideo(scenario, in: app)
    try startMatrixDownload(
      mode: "Audio",
      quality: nil,
      in: app
    )
    try openMatrixDownloads(in: app)
    try assertMatrixDownloadReadyAndPlayable(
      action: "Listen",
      playerIdentifier: "live.offline-audio-player",
      in: app
    )
  }

  func testLongFormYouTubePlaybackMatrix() throws {
    try runPlaybackMatrix(
      Array(LivePlaybackMatrixCase.current[0..<3])
    )
  }

  func testVariedYouTubePlaybackMatrix() throws {
    try runPlaybackMatrix(
      Array(LivePlaybackMatrixCase.current[3..<9])
    )
  }

  func testAdditionalYouTubeAndLivePlaybackMatrix() throws {
    try runPlaybackMatrix(
      Array(LivePlaybackMatrixCase.current[9..<14])
    )
  }

  func testBiliBiliAndNicoNicoPlaybackMatrix() throws {
    try runPlaybackMatrix(
      Array(LivePlaybackMatrixCase.current[14..<20])
    )
  }

  func testBiliBiliPlaybackMatrix() throws {
    try runPlaybackMatrix(
      Array(LivePlaybackMatrixCase.current[14..<17])
    )
  }

  func testNicoNicoPlaybackMatrix() throws {
    try runPlaybackMatrix(
      Array(LivePlaybackMatrixCase.current[17..<20])
    )
  }

  func testNicoNicoPlaybackSmoke() throws {
    try runPlaybackMatrix(
      [LivePlaybackMatrixCase.current[17]]
    )
  }

  private func runPlaybackMatrix(
    _ scenarios: [LivePlaybackMatrixCase]
  ) throws {
    XCTAssertFalse(scenarios.isEmpty)
    XCTAssertEqual(Set(scenarios.map(\.expectedID)).count, scenarios.count)
    let app = launchMatrixApp()
    var verified: [String] = []
    var activeServiceID = 0

    for (index, scenario) in scenarios.enumerated() {
      try XCTContext.runActivity(
        named: """
        \(index + 1)/\(scenarios.count) \
        \(scenario.provider) \(scenario.expectedID)
        """
      ) { activity in
        if activeServiceID != scenario.serviceID {
          try selectMatrixService(
            scenario.provider,
            in: app
          )
          activeServiceID = scenario.serviceID
        }

        let identifier = try openMatrixVideo(
          scenario,
          in: app
        )
        let start = try matrixPlaybackPosition(in: app)
        try assertMatrixPlaybackAdvances(
          in: app,
          seconds: scenario.holdSeconds
        )

        if let seekTarget = scenario.seekTarget {
          try exerciseMatrixSeek(
            in: app,
            chapterTitle: try XCTUnwrap(scenario.chapterTitle),
            target: seekTarget,
            sponsorSkipEnd: scenario.sponsorSkipEnd
          )
        }

        if scenario.expectsLive {
          let statistics = app.staticTexts["live.video.statistics"]
          XCTAssertTrue(statistics.waitForExistence(timeout: 10))
          XCTAssertTrue(
            statistics.label.localizedCaseInsensitiveContains("Live")
          )
        }

        let end = try matrixPlaybackPosition(in: app)
        let report = XCTAttachment(
          string: """
          provider=\(scenario.provider)
          query=\(scenario.query)
          expected=\(scenario.expectedID)
          selected=\(identifier)
          start=\(start)
          end=\(end)
          hold=\(scenario.holdSeconds)
          seek=\(scenario.seekTarget.map { String($0) } ?? "none")
          sponsorEnd=\(scenario.sponsorSkipEnd.map { String($0) } ?? "none")
          """
        )
        report.name = "Playback matrix \(index + 1)"
        report.lifetime = .keepAlways
        activity.add(report)
        verified.append(scenario.expectedID)
        closeMatrixVideo(in: app)
      }
    }

    XCTAssertEqual(verified.count, scenarios.count)
    XCTAssertEqual(Set(verified).count, scenarios.count)
    let summary = XCTAttachment(
      string: verified.enumerated().map {
        "\($0.offset + 1). \($0.element)"
      }.joined(separator: "\n")
    )
    summary.name = "Verified playback matrix"
    summary.lifetime = .keepAlways
    add(summary)
  }
}
