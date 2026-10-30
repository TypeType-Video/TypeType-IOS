import XCTest

@testable import TypeTypeIOS

final class LiveOriginalAudioChoiceTests: XCTestCase {
  private let english = LiveOriginalAudioChoiceTests.track(id: "en.4", locale: "en-US", isOriginal: true)
  private let french = LiveOriginalAudioChoiceTests.track(id: "fr.3", locale: "fr-FR", isOriginal: false)

  func testOriginalLanguageWinsOverTheChosenLanguage() {
    let choice = LivePlaybackPreferences.initialAudio(
      in: stream(original: "en.4"),
      language: "fr",
      preferOriginal: true
    )

    XCTAssertEqual(choice?.audioTrackID, "en.4")
  }

  func testTheOriginalFlagIsUsedWhenTheStreamNamesNoTrack() {
    let choice = LivePlaybackPreferences.initialAudio(
      in: stream(original: nil),
      language: "fr",
      preferOriginal: true
    )

    XCTAssertEqual(choice?.audioTrackID, "en.4")
  }

  func testTheChosenLanguageIsUsedWithoutTheOriginalPreference() {
    let choice = LivePlaybackPreferences.initialAudio(
      in: stream(original: "en.4"),
      language: "fr",
      preferOriginal: false
    )

    XCTAssertEqual(choice?.audioTrackID, "fr.3")
  }

  func testNoLanguageLeavesTheChoiceToTheServer() {
    let choice = LivePlaybackPreferences.initialAudio(
      in: stream(original: "en.4"),
      language: "",
      preferOriginal: false
    )

    XCTAssertNil(choice)
  }

  private func stream(original: String?) -> LivePlaybackStream {
    var stream = LivePlaybackStream(
      id: "abcdefghijk", title: "Fixture", uploaderName: "Channel", uploaderURL: "",
      uploaderAvatarURL: "", thumbnailURL: "", description: "", duration: 120,
      viewCount: 0, likeCount: 0, dislikeCount: 0, uploadDate: "", uploaded: -1,
      uploaderSubscriberCount: -1, uploaderVerified: false, publishedAt: nil, startPosition: 0,
      hlsURL: "", videoStreams: [], audioStreams: [french, english], videoOnlyStreams: [], subtitles: [],
      chapters: [], sponsorBlockSegments: [], relatedStreams: [], category: nil,
      isLive: false, isPostLive: false, isLiveContent: false
    )
    stream.originalAudioTrackID = original
    return stream
  }

  private static func track(id: String, locale: String, isOriginal: Bool) -> LivePlaybackAudioSource {
    LivePlaybackAudioSource(
      url: "https://sabr.example.com/\(id).m4s",
      mimeType: "audio/mp4",
      bitrate: 128_000,
      codec: "mp4a.40.2",
      quality: "medium",
      itag: 140,
      audioTrackID: id,
      audioTrackName: nil,
      audioLocale: locale,
      isOriginal: isOriginal,
      contentLength: 0,
      initStart: 0,
      initEnd: 907,
      indexStart: 908,
      indexEnd: 3_807,
      deliveryMethod: "sabr",
      manifestURL: nil
    )
  }
}
