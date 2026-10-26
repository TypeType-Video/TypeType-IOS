import XCTest
@testable import TypeTypeIOS

final class LiveSABRPrewarmsTests: XCTestCase {
  private func key(start: Int64 = 0) -> LiveSABRPrewarms.Key {
    LiveSABRPrewarms.Key(
      videoID: "abcdefghijk",
      request: LiveSABRPlaybackRequest(
        videoItag: 137,
        audioItag: 140,
        audioTrackID: nil,
        startTimeMS: start,
        playerTimeMS: start,
        audioOnly: false,
        isLive: false
      )
    )
  }

  func testCreateWaitsForPrewarmInFlight() async {
    let prewarms = LiveSABRPrewarms()
    let order = OrderRecorder()
    let started = expectation(description: "prewarm sent")
    let prewarm = Task {
      await prewarms.prewarm(key()) {
        started.fulfill()
        try? await Task.sleep(for: .milliseconds(150))
        await order.append("prewarm")
      }
    }
    await fulfillment(of: [started], timeout: 2)
    await prewarms.settle(key())
    await order.append("create")
    await prewarm.value
    let events = await order.events
    XCTAssertEqual(events, ["prewarm", "create"])
  }

  func testPrewarmAfterCreateIsDropped() async {
    let prewarms = LiveSABRPrewarms()
    let order = OrderRecorder()
    await prewarms.settle(key())
    await prewarms.prewarm(key()) { await order.append("prewarm") }
    let events = await order.events
    XCTAssertEqual(events, [])
  }

  func testSecondPrewarmOfSameRequestIsDropped() async {
    let prewarms = LiveSABRPrewarms()
    let order = OrderRecorder()
    await prewarms.prewarm(key()) { await order.append("first") }
    await prewarms.prewarm(key()) { await order.append("second") }
    await prewarms.prewarm(key(start: 5_000)) { await order.append("other start") }
    let events = await order.events
    XCTAssertEqual(events, ["first", "other start"])
  }
}

final class LivePlaybackStartPlanTests: XCTestCase {
  func testStartTimeKeepsResumeAwayFromTheEnd() {
    XCTAssertEqual(LivePlaybackPreparation.startTime(requested: 30, duration: 120), 30)
    XCTAssertEqual(LivePlaybackPreparation.startTime(requested: 116, duration: 120), 0)
    XCTAssertEqual(LivePlaybackPreparation.startTime(requested: 30, duration: 0), 0)
    XCTAssertEqual(LivePlaybackPreparation.startTime(requested: -3, duration: 120), 0)
  }

  func testInitialPreferencesPickTheSettingsAudioLanguage() {
    var settings = LiveSettings()
    settings.defaultQuality = "720p"
    settings.defaultAudioLanguage = "fr"
    let stream = streamWithAudio(locales: ["en-US", "fr-FR"])
    let preferences = LivePlaybackPreferences.initial(
      for: stream,
      settings: settings,
      audioOnly: true,
      preferredCodec: "h264"
    )
    XCTAssertEqual(preferences.quality, "720p")
    XCTAssertEqual(preferences.preferredCodec, "h264")
    XCTAssertEqual(preferences.audioTrackID, "track-fr-FR")
    XCTAssertEqual(preferences.audioSourceID, stream.audioStreams[1].id)
    XCTAssertTrue(preferences.audioOnly)
    XCTAssertNil(preferences.videoItag)
  }

  func testInitialPreferencesWithoutLanguageKeepDefaultAudio() {
    let preferences = LivePlaybackPreferences.initial(
      for: streamWithAudio(locales: ["en-US"]),
      settings: LiveSettings(),
      audioOnly: false,
      preferredCodec: "recommended"
    )
    XCTAssertNil(preferences.audioTrackID)
    XCTAssertNil(preferences.audioSourceID)
  }

  private func streamWithAudio(locales: [String]) -> LivePlaybackStream {
    let base = LivePlaybackFastStartTests.stream()
    let audio = locales.map { locale in
      LivePlaybackAudioSource(
        url: "/sabr/\(locale)", mimeType: "audio/mp4", bitrate: 128_000, codec: "mp4a.40.2",
        quality: nil, itag: 140, audioTrackID: "track-\(locale)", audioTrackName: nil,
        audioLocale: locale, isOriginal: false, contentLength: 0, initStart: 0, initEnd: 0,
        indexStart: 0, indexEnd: 0, deliveryMethod: "sabr", manifestURL: nil
      )
    }
    return LivePlaybackStream(
      id: base.id, title: base.title, uploaderName: "", uploaderURL: "", uploaderAvatarURL: "",
      thumbnailURL: "", description: "", duration: 120, viewCount: 0, likeCount: 0,
      dislikeCount: 0, uploadDate: "", uploaded: -1, uploaderSubscriberCount: -1,
      uploaderVerified: false, publishedAt: nil, startPosition: 0, hlsURL: "", videoStreams: [],
      audioStreams: audio, videoOnlyStreams: [], subtitles: [], chapters: [],
      sponsorBlockSegments: [], relatedStreams: [], category: nil, isLive: false,
      isPostLive: false, isLiveContent: false
    )
  }
}

private actor OrderRecorder {
  private(set) var events: [String] = []

  func append(_ event: String) {
    events.append(event)
  }
}
