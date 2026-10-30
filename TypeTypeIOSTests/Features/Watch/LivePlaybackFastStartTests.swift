import XCTest
@testable import TypeTypeIOS

final class LivePlaybackFastStartTests: XCTestCase {
  private let youtubeURL = "https://www.youtube.com/watch?v=abcdefghijk"

  func testYouTubePlaybackStartsFromTheBootstrapRoute() async throws {
    let client = RecordingStreamClient(stream: Self.stream())
    let service = Self.service(client)

    _ = try await service.playbackStream(for: youtubeURL)

    let paths = client.paths
    XCTAssertEqual(paths, ["/streams/youtube/sabr/bootstrap"])
  }

  func testFailedBootstrapFallsBackToFullExtraction() async throws {
    let client = RecordingStreamClient(stream: Self.stream(), failingPaths: ["/streams/youtube/sabr/bootstrap"])
    let service = Self.service(client)

    _ = try await service.playbackStream(for: youtubeURL)

    let paths = client.paths
    XCTAssertEqual(paths, ["/streams/youtube/sabr/bootstrap", "/streams/youtube/sabr"])
  }

  func testBootstrapFallbackOwnsItsRetries() async throws {
    let bootstrap = "/streams/youtube/sabr/bootstrap"
    let client = RecordingStreamClient(stream: Self.stream(), failingPaths: [bootstrap, "/streams/youtube/sabr"])
    let service = Self.service(client)

    do {
      _ = try await service.stream(for: youtubeURL)
      XCTFail("Every route failed, the stream should not load.")
    } catch {}

    XCTAssertEqual(client.paths, ["/streams/youtube/sabr"] + Array(repeating: bootstrap, count: 4))
    XCTAssertEqual(Array(client.transientRetries.dropFirst()), Array(repeating: false, count: 4))
  }

  func testDiscardedRequestIsAskedAgain() async throws {
    let client = RecordingStreamClient(stream: Self.stream(), delay: .milliseconds(400))
    let service = Self.service(client)

    let stuck = Task { try await service.stream(for: youtubeURL) }
    try await Task.sleep(for: .milliseconds(100))
    await service.discardPendingStreams(for: youtubeURL)
    _ = try await service.stream(for: youtubeURL)
    _ = try? await stuck.value

    XCTAssertEqual(client.paths, ["/streams/youtube/sabr", "/streams/youtube/sabr"])
  }

  func testConcurrentRequestsForOneVideoShareOneFetch() async throws {
    let client = RecordingStreamClient(stream: Self.stream(), delay: .milliseconds(150))
    let service = Self.service(client)

    async let first = service.stream(for: youtubeURL)
    async let second = service.stream(for: youtubeURL)
    _ = try await (first, second)

    let paths = client.paths
    XCTAssertEqual(paths, ["/streams/youtube/sabr"])
  }

  func testLiveStreamsAreNeverCached() async throws {
    let client = RecordingStreamClient(stream: Self.stream(isLive: true))
    let service = Self.service(client)

    _ = try await service.stream(for: youtubeURL)
    _ = try await service.stream(for: youtubeURL)

    let paths = client.paths
    XCTAssertEqual(paths.count, 2)
  }

  func testYouTubeLivePlaysTheServerManifestNatively() throws {
    let service = Self.service(RecordingStreamClient(stream: Self.stream()))
    let live = Self.stream(isLive: true, hlsURL: "/streams/hls-manifest?token=ph1.abc")

    let preparation = try service.prepare(
      stream: live,
      sourceURL: youtubeURL,
      preferences: LivePlaybackPreferences(
        quality: "", preferredCodec: "", videoItag: nil, videoSourceID: nil,
        audioTrackID: nil, audioSourceID: nil, audioOnly: false
      )
    )

    XCTAssertFalse(preparation.isSABR)
    XCTAssertFalse(preparation.usesAuthenticatedLoader)
    XCTAssertEqual(
      preparation.assetURL?.absoluteString,
      "https://watch.typetype.video/api/streams/hls-manifest?token=ph1.abc"
    )
  }

  func testAbsoluteLiveManifestIsKept() {
    let service = Self.service(RecordingStreamClient(stream: Self.stream()))
    XCTAssertEqual(
      service.serverResourceURL(for: "https://cdn.example/live.m3u8")?.absoluteString,
      "https://cdn.example/live.m3u8"
    )
    XCTAssertNil(service.serverResourceURL(for: "  "))
  }

  func testWarmupTakesInitAndFirstSegments() {
    let playlist = """
      #EXTM3U
      #EXT-X-MAP:URI="http://127.0.0.1:5/resource/init.mp4"
      #EXT-X-KEY:METHOD=AES-128,URI="http://127.0.0.1:5/resource/key.bin",IV=0x01
      #EXTINF:5.0,
      http://127.0.0.1:5/resource/one.m4s
      #EXTINF:5.0,
      http://127.0.0.1:5/resource/two.m4s
      #EXTINF:5.0,
      http://127.0.0.1:5/resource/three.m4s
      """

    XCTAssertEqual(
      LivePlaybackHTTPServer.startResourcePaths(in: playlist, segmentCount: 2),
      ["/resource/init.mp4", "/resource/key.bin", "/resource/one.m4s", "/resource/two.m4s"]
    )
  }

  func testWarmupStartsAtTheResumePosition() {
    let playlist = """
      #EXTM3U
      #EXT-X-START:TIME-OFFSET=12.500,PRECISE=YES
      #EXT-X-MAP:URI="http://127.0.0.1:5/resource/init.mp4"
      #EXTINF:5.000,
      http://127.0.0.1:5/resource/s1.m4s
      #EXTINF:5.000,
      http://127.0.0.1:5/resource/s2.m4s
      #EXTINF:5.000,
      http://127.0.0.1:5/resource/s3.m4s
      #EXTINF:5.000,
      http://127.0.0.1:5/resource/s4.m4s
      #EXTINF:5.000,
      http://127.0.0.1:5/resource/s5.m4s
      """

    XCTAssertEqual(
      LivePlaybackHTTPServer.startResourcePaths(in: playlist, segmentCount: 2),
      ["/resource/init.mp4", "/resource/s3.m4s", "/resource/s4.m4s"]
    )
  }

  private static func service(_ client: RecordingStreamClient) -> LivePlaybackService {
    LivePlaybackService(
      apiClient: client,
      serverURLProvider: { URL(string: "https://watch.typetype.video/api") }
    )
  }

  static func stream(isLive: Bool = false, hlsURL: String = "") -> LivePlaybackStream {
    LivePlaybackStream(
      id: "abcdefghijk", title: "Fixture", uploaderName: "Channel", uploaderURL: "",
      uploaderAvatarURL: "", thumbnailURL: "", description: "", duration: isLive ? 0 : 120,
      viewCount: 0, likeCount: 0, dislikeCount: 0, uploadDate: "", uploaded: -1,
      uploaderSubscriberCount: -1, uploaderVerified: false, publishedAt: nil, startPosition: 0,
      hlsURL: hlsURL, videoStreams: [], audioStreams: [], videoOnlyStreams: [], subtitles: [],
      chapters: [], sponsorBlockSegments: [], relatedStreams: [], category: nil,
      isLive: isLive, isPostLive: false, isLiveContent: isLive
    )
  }
}

final class RecordingStreamClient: APIClient, @unchecked Sendable {
  private let lock = NSLock()
  private var recordedPaths: [String] = []
  private var recordedRetries: [Bool] = []
  private let stream: LivePlaybackStream
  private let failingPaths: Set<String>
  private let delay: Duration?

  var paths: [String] { lock.withLock { recordedPaths } }
  var transientRetries: [Bool] { lock.withLock { recordedRetries } }

  init(stream: LivePlaybackStream, failingPaths: Set<String> = [], delay: Duration? = nil) {
    self.stream = stream
    self.failingPaths = failingPaths
    self.delay = delay
  }

  func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
    lock.withLock {
      recordedPaths.append(endpoint.path)
      recordedRetries.append(endpoint.retriesTransientFailures)
    }
    if let delay { try await Task.sleep(for: delay) }
    if failingPaths.contains(endpoint.path) { throw NetworkError.statusCode(503, nil) }
    guard let value = stream as? T else { throw NetworkError.invalidResponse }
    return value
  }

  func request(_ endpoint: APIEndpoint) async throws { throw NetworkError.invalidResponse }

  func requestData(_ endpoint: APIEndpoint) async throws -> Data { throw NetworkError.invalidResponse }
}

final class LiveDescriptionEntityTests: XCTestCase {
  func testEntitiesAreDecodedWithoutTheHTMLImporter() {
    XCTAssertEqual(
      LiveDescriptionTextFormatter.decodingHTMLEntities(in: "Tom &amp; Jerry &#12354;&#x3042; &lt;3 &unknown; & done"),
      "Tom & Jerry ああ <3 &unknown; & done"
    )
  }

  func testNicoNicoDescriptionKeepsLinesAndLinks() {
    let text = LiveDescriptionTextFormatter.displayText(
      "Hello<br>world &quot;quoted&quot; <a href=\"https://nico.ms/sm9\">sm9</a>",
      sourceURL: "https://www.nicovideo.jp/watch/sm1"
    )
    XCTAssertEqual(text, "Hello\nworld \"quoted\" sm9 (https://nico.ms/sm9)")
  }
}

final class LiveServerMediaPreparationTests: XCTestCase {
  private let preferences = LivePlaybackPreferences(
    quality: "", preferredCodec: "", videoItag: nil, videoSourceID: nil,
    audioTrackID: nil, audioSourceID: nil, audioOnly: false
  )

  func testBiliBiliServerMediaIsLoadedDirectlyFromTheAPI() throws {
    let preparation = try service().prepare(
      stream: stream(
        video: video(url: "/media/m1_video", method: "progressive", codec: "avc1.640032", initEnd: 934),
        audio: audio(url: "/media/m1_audio", method: "progressive", codec: "mp4a.40.2", initEnd: 900)
      ),
      sourceURL: "https://www.bilibili.com/video/BV1abc?p=1",
      preferences: preferences
    )

    guard case let .separateProgressive(videoURL, audioURL)? = preparation.providerPlayback else {
      return XCTFail("BiliBili should play separate progressive tracks.")
    }
    XCTAssertEqual(videoURL.absoluteString, "typetype-sabr://watch.typetype.video/api/media/m1_video")
    XCTAssertEqual(audioURL.absoluteString, "typetype-sabr://watch.typetype.video/api/media/m1_audio")
  }

  func testNicoNicoMislabeledAudioPairsWithHLSVideo() throws {
    let preparation = try service().prepare(
      stream: stream(
        video: video(url: "/media/m1_video", method: "hls", codec: nil, initEnd: 0),
        audio: audio(url: "/media/m1_audio", method: "progressive", codec: nil, initEnd: 0)
      ),
      sourceURL: "https://www.nicovideo.jp/watch/sm46963734",
      preferences: preferences
    )

    guard case let .separateHLS(videoURL, audioURL)? = preparation.providerPlayback else {
      return XCTFail("NicoNico should play separate HLS tracks.")
    }
    XCTAssertEqual(videoURL.path, "/api/media/m1_video")
    XCTAssertEqual(audioURL.path, "/api/media/m1_audio")
  }

  func testHEVCIsPreferredOverH264AtTheSameHeight() {
    let avc = video(url: "/media/avc", method: "progressive", codec: "avc1.640032", initEnd: 900)
    let hevc = video(url: "/media/hevc", method: "progressive", codec: "hvc1.1.6.L150.90", initEnd: 900)
    let picked = service().selectVideo(from: [avc, hevc], quality: "1080p", requestedItag: nil)
    XCTAssertEqual(picked?.url, "/media/hevc")
    XCTAssertEqual(
      service().selectVideo(from: [avc, hevc], quality: "1080p", preferredCodec: "h264", requestedItag: nil)?.url,
      "/media/avc"
    )
  }

  private func service() -> LivePlaybackService {
    LivePlaybackService(
      apiClient: RecordingStreamClient(stream: LivePlaybackFastStartTests.stream()),
      serverURLProvider: { URL(string: "https://watch.typetype.video/api") }
    )
  }

  private func video(url: String, method: String, codec: String?, initEnd: Int64) -> LivePlaybackVideoSource {
    LivePlaybackVideoSource(
      url: url, mimeType: "video/mp4", resolution: "720p", bitrate: 1_000_000, codec: codec,
      isVideoOnly: true, itag: -1, width: 1280, height: 720, fps: 30, contentLength: 0,
      initStart: 0, initEnd: initEnd, indexStart: initEnd == 0 ? 0 : initEnd + 1,
      indexEnd: initEnd == 0 ? 0 : initEnd + 500, deliveryMethod: method, manifestURL: nil
    )
  }

  private func audio(url: String, method: String, codec: String?, initEnd: Int64) -> LivePlaybackAudioSource {
    LivePlaybackAudioSource(
      url: url, mimeType: "audio/mp4", bitrate: 128_000, codec: codec, quality: nil, itag: -1,
      audioTrackID: nil, audioTrackName: nil, audioLocale: nil, isOriginal: false, contentLength: 0,
      initStart: 0, initEnd: initEnd, indexStart: initEnd == 0 ? 0 : initEnd + 1,
      indexEnd: initEnd == 0 ? 0 : initEnd + 500, deliveryMethod: method, manifestURL: nil
    )
  }

  private func stream(video: LivePlaybackVideoSource, audio: LivePlaybackAudioSource) -> LivePlaybackStream {
    let base = LivePlaybackFastStartTests.stream()
    return LivePlaybackStream(
      id: "provider", title: base.title, uploaderName: "", uploaderURL: "", uploaderAvatarURL: "",
      thumbnailURL: "", description: "", duration: 100, viewCount: 0, likeCount: 0, dislikeCount: 0,
      uploadDate: "", uploaded: -1, uploaderSubscriberCount: -1, uploaderVerified: false,
      publishedAt: nil, startPosition: 0, hlsURL: "", videoStreams: [], audioStreams: [audio],
      videoOnlyStreams: [video], subtitles: [], chapters: [], sponsorBlockSegments: [],
      relatedStreams: [], category: nil, isLive: false, isPostLive: false, isLiveContent: false
    )
  }
}

final class LiveStartupBudgetTests: XCTestCase {
  @MainActor
  func testOnlyTransientFailuresAreRetried() {
    XCTAssertTrue(LivePlayerController.isTransientStartupFailure(LivePlaybackFailure.invalidSABRContract))
    XCTAssertTrue(LivePlayerController.isTransientStartupFailure(NetworkError.statusCode(503, nil)))
    XCTAssertTrue(LivePlayerController.isTransientStartupFailure(URLError(.timedOut)))
    XCTAssertFalse(LivePlayerController.isTransientStartupFailure(LivePlaybackFailure.noPlayableSource))
    XCTAssertFalse(LivePlayerController.isTransientStartupFailure(NetworkError.statusCode(404, nil)))
  }

  @MainActor
  func testInstanceRefusalsShowTheirOwnWords() {
    XCTAssertEqual(
      LivePlayerController.message(for: NetworkError.statusCode(422, "This video is only available in Japan")),
      "This video is only available in Japan"
    )
  }
}

final class LiveSABRSegmentContinuityTests: XCTestCase {
  func testRoundedOverlapsBetweenSegmentsAreAccepted() {
    // Seen on a resumed video: 337837 + 6257 = 344094, next segment at 344091.
    XCTAssertTrue(LiveSABRPlaybackSession.segmentFollows(startMS: 344_091, previousEndMS: 344_094))
    XCTAssertTrue(LiveSABRPlaybackSession.segmentFollows(startMS: 0, previousEndMS: -1))
    XCTAssertFalse(LiveSABRPlaybackSession.segmentFollows(startMS: 300_000, previousEndMS: 344_094))
  }
}
