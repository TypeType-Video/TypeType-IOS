import CoreMedia
import XCTest

@testable import TypeTypeIOS

final class LiveDownloadVideoQualitiesTests: XCTestCase {
  private let stream = LiveDownloadVideoQualitiesTests.stream(videos: [
    video(height: 2160, codec: "av01.0.12M.08"),
    video(height: 2160, codec: "vp9", mimeType: "video/webm"),
    video(height: 1440, codec: "av01.0.08M.08"),
    video(height: 1080, codec: "avc1.640028"),
    video(height: 1080, codec: "av01.0.08M.08"),
    video(height: 720, codec: nil),
  ])

  func testAV1DeviceGetsQualitiesAbove1080pInAV1AndKeepsH264Below() {
    let qualities = LiveDownloadVideoQualities(stream: stream) { $0 == kCMVideoCodecType_AV1 }

    XCTAssertEqual(qualities.options, [
      LiveDownloadVideoQuality(height: 2160, codecPrefix: "av01"),
      LiveDownloadVideoQuality(height: 1440, codecPrefix: "av01"),
      LiveDownloadVideoQuality(height: 1080, codecPrefix: "avc1"),
      LiveDownloadVideoQuality(height: 720, codecPrefix: "avc1"),
    ])
    XCTAssertFalse(qualities.hidesUnplayableHigherQualities)
    XCTAssertEqual(qualities.defaultValue, "1080p")
    XCTAssertEqual(qualities.option(for: "2160p")?.requestCodec, "av01")
    XCTAssertEqual(qualities.option(for: "1080p")?.requestCodec, "h264")
  }

  func testDeviceWithoutAV1StopsAt1080pAndSaysWhy() {
    let qualities = LiveDownloadVideoQualities(stream: stream) { _ in false }

    XCTAssertEqual(qualities.options.map(\.value), ["1080p", "720p"])
    XCTAssertTrue(qualities.hidesUnplayableHigherQualities)
  }

  func testStreamWithoutVideoOnlySourcesKeepsTheH264Fallback() {
    let qualities = LiveDownloadVideoQualities(stream: Self.stream(videos: [])) { _ in true }

    XCTAssertEqual(qualities.options, LiveDownloadVideoQualities.fallback)
    XCTAssertFalse(qualities.hidesUnplayableHigherQualities)
  }

  func testSizeEstimateFollowsTheChosenCodec() {
    XCTAssertEqual(
      LiveDownloadSizeEstimate.bytes(for: stream, mode: .video, quality: "2160p", videoCodecPrefix: "av01"),
      2_160
    )
    XCTAssertEqual(LiveDownloadSizeEstimate.bytes(for: stream, mode: .video, quality: "2160p"), 1_080)
  }

  private static func video(height: Int, codec: String?, mimeType: String = "video/mp4") -> LivePlaybackVideoSource {
    LivePlaybackVideoSource(
      url: "https://media.example.com/\(height)-\(codec ?? "none")", mimeType: mimeType, resolution: "\(height)p",
      bitrate: height * 1_000, codec: codec, isVideoOnly: true, itag: height, width: height * 16 / 9,
      height: height, fps: 30, contentLength: Int64(height), initStart: 0, initEnd: 0, indexStart: 0, indexEnd: 0,
      deliveryMethod: "url", manifestURL: nil
    )
  }

  private static func stream(videos: [LivePlaybackVideoSource]) -> LivePlaybackStream {
    LivePlaybackStream(
      id: "fixture", title: "Fixture", uploaderName: "Channel", uploaderURL: "", uploaderAvatarURL: "",
      thumbnailURL: "", description: "", duration: 100, viewCount: 0, likeCount: 0, dislikeCount: 0,
      uploadDate: "", uploaded: -1, uploaderSubscriberCount: -1, uploaderVerified: false, publishedAt: nil,
      startPosition: 0, hlsURL: "", videoStreams: [], audioStreams: [], videoOnlyStreams: videos,
      subtitles: [], chapters: [], sponsorBlockSegments: [], relatedStreams: [], category: nil, isLive: false,
      isPostLive: false, isLiveContent: false
    )
  }
}
