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

  func testTheChoiceIsAlwaysATrackTheMenuOffers() {
    let opus = LiveOriginalAudioChoiceTests.track(
      id: "en.4", locale: "en-US", isOriginal: true, mimeType: "audio/webm", codec: "opus", itag: 251
    )
    let stream = stream(original: "en.4", audio: [opus, french, english])

    let choice = LivePlaybackPreferences.initialAudio(in: stream, language: "", preferOriginal: true)

    XCTAssertEqual(choice?.id, english.id)
    XCTAssertTrue(stream.playableAudioSources.contains { $0.id == choice?.id })
  }

  private func stream(original: String?, audio: [LivePlaybackAudioSource]? = nil) -> LivePlaybackStream {
    var stream = LivePlaybackStream(
      id: "abcdefghijk", title: "Fixture", uploaderName: "Channel", uploaderURL: "",
      uploaderAvatarURL: "", thumbnailURL: "", description: "", duration: 120,
      viewCount: 0, likeCount: 0, dislikeCount: 0, uploadDate: "", uploaded: -1,
      uploaderSubscriberCount: -1, uploaderVerified: false, publishedAt: nil, startPosition: 0,
      hlsURL: "", videoStreams: [], audioStreams: audio ?? [french, english], videoOnlyStreams: [], subtitles: [],
      chapters: [], sponsorBlockSegments: [], relatedStreams: [], category: nil,
      isLive: false, isPostLive: false, isLiveContent: false
    )
    stream.originalAudioTrackID = original
    return stream
  }

  private static func track(
    id: String,
    locale: String,
    isOriginal: Bool,
    mimeType: String = "audio/mp4",
    codec: String = "mp4a.40.2",
    itag: Int = 140
  ) -> LivePlaybackAudioSource {
    LivePlaybackAudioSource(
      url: "https://sabr.example.com/\(id).m4s",
      mimeType: mimeType,
      bitrate: 128_000,
      codec: codec,
      quality: "medium",
      itag: itag,
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
