import XCTest
@testable import TypeTypeIOS

final class LiveProviderPlaybackPreparationTests: XCTestCase {
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
