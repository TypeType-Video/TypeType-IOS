import XCTest
@testable import TypeTypeIOS

final class LiveProviderPlaybackPreparationTests: XCTestCase {
  func testBiliBiliProgressiveSourcesUseInstanceProxy() throws {
    let videoURL =
      "https://upos-sz-mirrorali.bilivideo.com/upgcxcode/video.m4s?token=1"
    let audioURL =
      "https://upos-sz-mirrorali.bilivideo.com/upgcxcode/audio.m4s?token=2"
    let video = LivePlaybackVideoSource(
      url: videoURL,
      mimeType: "video/mp4",
      resolution: "720p",
      bitrate: 1_000_000,
      codec: "avc1.640020",
      isVideoOnly: true,
      itag: -1,
      width: 1280,
      height: 720,
      fps: 30,
      contentLength: 0,
      initStart: 0,
      initEnd: 977,
      indexStart: 978,
      indexEnd: 3_877,
      deliveryMethod: "progressive",
      manifestURL: nil
    )
    let audio = LivePlaybackAudioSource(
      url: audioURL,
      mimeType: "audio/mp4",
      bitrate: 128_000,
      codec: "mp4a",
      quality: "medium",
      itag: -1,
      audioTrackID: nil,
      audioTrackName: nil,
      audioLocale: nil,
      isOriginal: false,
      contentLength: 0,
      initStart: 0,
      initEnd: 907,
      indexStart: 908,
      indexEnd: 3_807,
      deliveryMethod: "progressive",
      manifestURL: nil
    )
    let service = LivePlaybackService(
      apiClient: ProviderAPIClientStub(),
      serverURLProvider: {
        URL(string: "https://watch.typetype.video/api")
      }
    )

    let preparation = try service.prepare(
      stream: stream(
        id: "BV1cN411d74Q",
        video: video,
        audio: audio
      ),
      sourceURL: "https://www.bilibili.com/video/BV1cN411d74Q?p=1",
      preferences: preferences
    )

    guard
      case let .separateProgressive(
        preparedVideoURL,
        preparedAudioURL
      )? = preparation.providerPlayback
    else {
      return XCTFail("BiliBili should use separate progressive playback.")
    }
    XCTAssertEqual(
      preparedVideoURL.scheme,
      LivePlaybackService.authenticatedScheme
    )
    XCTAssertEqual(preparedVideoURL.host, "watch.typetype.video")
    XCTAssertEqual(preparedVideoURL.path, "/api/proxy")
    XCTAssertEqual(
      URLComponents(
        url: preparedVideoURL,
        resolvingAgainstBaseURL: false
      )?.queryItems?.first(where: { $0.name == "url" })?.value,
      videoURL
    )
    XCTAssertEqual(
      preparedAudioURL.scheme,
      LivePlaybackService.authenticatedScheme
    )
    XCTAssertEqual(preparedAudioURL.host, "watch.typetype.video")
    XCTAssertEqual(preparedAudioURL.path, "/api/proxy")
    XCTAssertEqual(
      URLComponents(
        url: preparedAudioURL,
        resolvingAgainstBaseURL: false
      )?.queryItems?.first(where: { $0.name == "url" })?.value,
      audioURL
    )
    XCTAssertTrue(preparation.usesAuthenticatedLoader)
  }

  func testNicoNicoHLSAudioIsAcceptedWhenMethodIsMislabeled() throws {
    let sourceURL = "https://www.nicovideo.jp/watch/sm46594288"
    let video = LivePlaybackVideoSource(
      url: "https://delivery.example/video-h264-720p.m3u8?token=1",
      mimeType: "video/mp4",
      resolution: "720p",
      bitrate: nil,
      codec: nil,
      isVideoOnly: true,
      itag: -1,
      width: 0,
      height: 0,
      fps: 30,
      contentLength: 0,
      initStart: 0,
      initEnd: 0,
      indexStart: 0,
      indexEnd: 0,
      deliveryMethod: "hls",
      manifestURL: nil
    )
    let audio = LivePlaybackAudioSource(
      url: "https://delivery.example/audio-aac-192kbps.m3u8?token=1",
      mimeType: "audio/mp4",
      bitrate: nil,
      codec: nil,
      quality: nil,
      itag: -1,
      audioTrackID: nil,
      audioTrackName: nil,
      audioLocale: nil,
      isOriginal: true,
      contentLength: 0,
      initStart: 0,
      initEnd: 0,
      indexStart: 0,
      indexEnd: 0,
      deliveryMethod: "progressive",
      manifestURL: nil
    )
    let stream = LivePlaybackStream(
      id: "sm46594288",
      title: "NicoNico fixture",
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
      videoStreams: [],
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
    let service = LivePlaybackService(
      apiClient: ProviderAPIClientStub(),
      serverURLProvider: {
        URL(string: "https://watch.typetype.video/api")
      }
    )

    let preparation = try service.prepare(
      stream: stream,
      sourceURL: sourceURL,
      preferences: LivePlaybackPreferences(
        quality: "720p",
        videoItag: nil,
        videoSourceID: nil,
        audioTrackID: nil,
        audioSourceID: nil,
        audioOnly: false
      )
    )

    guard case .separateHLS? = preparation.providerPlayback else {
      return XCTFail("NicoNico sources should use separate HLS playback.")
    }
  }

  func testNicoNicoDescriptionBecomesReadableText() {
    let value = LiveDescriptionTextFormatter.displayText(
      """
      First line<br>Second &amp; third<br>
      <a href="https://example.com/list">Playlist</a>
      """,
      sourceURL: "https://www.nicovideo.jp/watch/sm1"
    )

    XCTAssertEqual(
      value,
      "First line\nSecond & third\n\nPlaylist (https://example.com/list)"
    )
  }

  private var preferences: LivePlaybackPreferences {
    LivePlaybackPreferences(
      quality: "720p",
      videoItag: nil,
      videoSourceID: nil,
      audioTrackID: nil,
      audioSourceID: nil,
      audioOnly: false
    )
  }

  private func stream(
    id: String,
    video: LivePlaybackVideoSource,
    audio: LivePlaybackAudioSource
  ) -> LivePlaybackStream {
    LivePlaybackStream(
      id: id,
      title: "Provider fixture",
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
      videoStreams: [],
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

private final class ProviderAPIClientStub: APIClient {
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
