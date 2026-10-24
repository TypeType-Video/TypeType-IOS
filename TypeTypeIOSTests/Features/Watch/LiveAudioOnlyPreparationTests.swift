import XCTest
@testable import TypeTypeIOS

final class LiveAudioOnlyPreparationTests: XCTestCase {
  func testAudioOnlyAcceptsNonH264Video() throws {
    // The video track is never decoded in audio-only mode: its itag only
    // echoes through the SABR session contract. A VP9-only video must not
    // fail preparation when audio-only is requested.
    let preparation = try service.prepare(
      stream: stream(
        id: "vp9-only",
        video: sabrVideo(codec: "vp09.00.10.08", mimeType: "video/webm"),
        audio: sabrAudio(codec: "mp4a.40.2")
      ),
      sourceURL: "https://www.youtube.com/watch?v=vp9only00001",
      preferences: preferences(audioOnly: true)
    )

    XCTAssertTrue(preparation.audioOnly)
    XCTAssertEqual(preparation.video?.codec, "vp09.00.10.08")
    XCTAssertEqual(preparation.audio?.codec, "mp4a.40.2")
  }

  func testAudioOnlyFallsBackToNonAACAudio() throws {
    // AAC is what the platform decodes reliably, but a video with only
    // Opus SABR audio should still play in audio-only instead of failing
    // with noPlayableSource.
    let preparation = try service.prepare(
      stream: stream(
        id: "opus-only",
        video: sabrVideo(codec: "avc1.640028", mimeType: "video/mp4"),
        audio: sabrAudio(codec: "opus", mimeType: "audio/webm")
      ),
      sourceURL: "https://www.youtube.com/watch?v=opusonly00001",
      preferences: preferences(audioOnly: true)
    )

    XCTAssertTrue(preparation.audioOnly)
    XCTAssertEqual(preparation.audio?.codec, "opus")
    XCTAssertEqual(preparation.video?.codec, "avc1.640028")
  }

  func testVideoPlaybackStillRejectsNonH264Video() {
    // The codec relaxation is scoped to audio-only: regular playback still
    // needs the H.264 track it actually decodes.
    XCTAssertThrowsError(
      try service.prepare(
        stream: stream(
          id: "vp9-strict",
          video: sabrVideo(codec: "vp09.00.10.08", mimeType: "video/webm"),
          audio: sabrAudio(codec: "mp4a.40.2")
        ),
        sourceURL: "https://www.youtube.com/watch?v=vp9strict0001",
        preferences: preferences(audioOnly: false)
      )
    )
  }

  func testProviderPreparationHonorsAudioOnly() throws {
    // The provider path used to hardcode audioOnly to false, so the toggle
    // was silently ignored outside the SABR path.
    let preparation = try service.prepare(
      stream: muxedProviderStream(id: "provider-muxed"),
      sourceURL: "https://www.bilibili.com/video/BV1cN411d74Q",
      preferences: preferences(audioOnly: true)
    )

    XCTAssertTrue(preparation.audioOnly)
    XCTAssertFalse(preparation.isSABR)
    XCTAssertNotNil(preparation.assetURL)
  }

  private var service: LivePlaybackService {
    LivePlaybackService(
      apiClient: AudioOnlyAPIClientStub(),
      serverURLProvider: {
        URL(string: "https://watch.typetype.video/api")
      }
    )
  }

  private func preferences(audioOnly: Bool) -> LivePlaybackPreferences {
    LivePlaybackPreferences(
      quality: "720p",
      videoItag: nil,
      videoSourceID: nil,
      audioTrackID: nil,
      audioSourceID: nil,
      audioOnly: audioOnly
    )
  }

  private func sabrVideo(codec: String, mimeType: String) -> LivePlaybackVideoSource {
    LivePlaybackVideoSource(
      url: "https://sabr.example.com/video.m4s",
      mimeType: mimeType,
      resolution: "720p",
      bitrate: 1_000_000,
      codec: codec,
      isVideoOnly: true,
      itag: 247,
      width: 1280,
      height: 720,
      fps: 30,
      contentLength: 0,
      initStart: 0,
      initEnd: 977,
      indexStart: 978,
      indexEnd: 3_877,
      deliveryMethod: "sabr",
      manifestURL: nil
    )
  }

  private func sabrAudio(codec: String, mimeType: String) -> LivePlaybackAudioSource {
    LivePlaybackAudioSource(
      url: "https://sabr.example.com/audio.m4s",
      mimeType: mimeType,
      bitrate: 128_000,
      codec: codec,
      quality: "medium",
      itag: 251,
      audioTrackID: nil,
      audioTrackName: nil,
      audioLocale: nil,
      isOriginal: true,
      contentLength: 0,
      initStart: 0,
      initEnd: 907,
      indexStart: 908,
      indexEnd: 3_807,
      deliveryMethod: "sabr",
      manifestURL: nil
    )
  }

  private func muxedProviderStream(id: String) -> LivePlaybackStream {
    let muxed = LivePlaybackVideoSource(
      url: "https://upos.example.com/video.mp4",
      mimeType: "video/mp4",
      resolution: "720p",
      bitrate: 1_000_000,
      codec: "avc1.640020",
      isVideoOnly: false,
      itag: -1,
      width: 1280,
      height: 720,
      fps: 30,
      contentLength: 0,
      initStart: 0,
      initEnd: 0,
      indexStart: 0,
      indexEnd: 0,
      deliveryMethod: "progressive",
      manifestURL: nil
    )
    return stream(id: id, video: muxed, audio: sabrAudio(codec: "mp4a.40.2", mimeType: "audio/mp4"), videoStreams: [muxed])
  }

  private func stream(
    id: String,
    video: LivePlaybackVideoSource,
    audio: LivePlaybackAudioSource,
    videoStreams: [LivePlaybackVideoSource] = []
  ) -> LivePlaybackStream {
    LivePlaybackStream(
      id: id,
      title: "Audio-only fixture",
      uploaderName: "Channel",
      uploaderURL: "",
      uploaderAvatarURL: "",
      thumbnailURL: "",
      description: "",
      duration: 442,
      viewCount: 0,
      likeCount: 0,
      dislikeCount: 0,
      uploadDate: "",
      uploaded: -1,
      uploaderSubscriberCount: -1,
      uploaderVerified: false,
      publishedAt: nil,
      startPosition: 0,
      hlsURL: "",
      videoStreams: videoStreams,
      audioStreams: [audio],
      videoOnlyStreams: [video],
      subtitles: [],
      chapters: [],
      sponsorBlockSegments: [],
      relatedStreams: [],
      category: nil,
      isLive: false,
      isPostLive: false,
      isLiveContent: false
    )
  }
}

private final class AudioOnlyAPIClientStub: APIClient {
  func request<T: Decodable>(
    _ endpoint: APIEndpoint,
    as type: T.Type
  ) async throws -> T {
    throw NetworkError.invalidResponse
  }

  func request(_ endpoint: APIEndpoint) async throws {
    throw NetworkError.invalidResponse
  }

  func requestData(_ endpoint: APIEndpoint) async throws -> Data {
    throw NetworkError.invalidResponse
  }
}
