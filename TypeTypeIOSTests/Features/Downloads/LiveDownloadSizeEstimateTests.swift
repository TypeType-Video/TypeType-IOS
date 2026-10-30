import XCTest

@testable import TypeTypeIOS

final class LiveDownloadSizeEstimateTests: XCTestCase {
  func testVideoPicksTheDownloaderStreamUnderTheHeightPlusBestAudio() {
    let stream = Self.stream(
      videos: [
        Self.video(height: 2160, codec: "avc1.640033", bytes: 900),
        Self.video(height: 1080, codec: "avc1.640028", bytes: 300),
        Self.video(height: 1080, codec: "vp09.00.40.08", bytes: 250),
        Self.video(height: 720, codec: "avc1.4d401f", bytes: 150),
      ],
      audios: [
        Self.audio(bitrate: 128_000, original: true, bytes: 40),
        Self.audio(bitrate: 256_000, original: false, bytes: 80),
      ]
    )

    XCTAssertEqual(LiveDownloadSizeEstimate.bytes(for: stream, mode: .video, quality: "1080p"), 340)
    XCTAssertEqual(LiveDownloadSizeEstimate.bytes(for: stream, mode: .video, quality: "1440p"), 340)
    XCTAssertEqual(LiveDownloadSizeEstimate.bytes(for: stream, mode: .audio, quality: "best"), 40)
    XCTAssertNil(LiveDownloadSizeEstimate.bytes(for: stream, mode: .thumbnail, quality: "best"))
  }

  func testUnknownLengthFallsBackToBitrateTimesDuration() {
    let stream = Self.stream(videos: [], audios: [Self.audio(bitrate: 160_000, original: true, bytes: 0)])

    XCTAssertEqual(LiveDownloadSizeEstimate.bytes(for: stream, mode: .audio, quality: "best"), 160_000 * 100 / 8)
  }

  private static func video(height: Int, codec: String, bytes: Int64) -> LivePlaybackVideoSource {
    LivePlaybackVideoSource(
      url: "https://media.example.com/\(height)-\(codec)", mimeType: "video/mp4", resolution: "\(height)p",
      bitrate: height * 1_000, codec: codec, isVideoOnly: true, itag: height, width: height * 16 / 9,
      height: height, fps: 30, contentLength: bytes, initStart: 0, initEnd: 0, indexStart: 0, indexEnd: 0,
      deliveryMethod: "url", manifestURL: nil
    )
  }

  private static func audio(bitrate: Int, original: Bool, bytes: Int64) -> LivePlaybackAudioSource {
    LivePlaybackAudioSource(
      url: "https://media.example.com/\(bitrate)", mimeType: "audio/mp4", bitrate: bitrate, codec: "mp4a.40.2",
      quality: nil, itag: bitrate, audioTrackID: nil, audioTrackName: nil, audioLocale: nil, isOriginal: original,
      contentLength: bytes, initStart: 0, initEnd: 0, indexStart: 0, indexEnd: 0, deliveryMethod: "url",
      manifestURL: nil
    )
  }

  private static func stream(videos: [LivePlaybackVideoSource], audios: [LivePlaybackAudioSource]) -> LivePlaybackStream {
    LivePlaybackStream(
      id: "fixture", title: "Fixture", uploaderName: "Channel", uploaderURL: "", uploaderAvatarURL: "",
      thumbnailURL: "", description: "", duration: 100, viewCount: 0, likeCount: 0, dislikeCount: 0,
      uploadDate: "", uploaded: -1, uploaderSubscriberCount: -1, uploaderVerified: false, publishedAt: nil,
      startPosition: 0, hlsURL: "", videoStreams: [], audioStreams: audios, videoOnlyStreams: videos,
      subtitles: [], chapters: [], sponsorBlockSegments: [], relatedStreams: [], category: nil, isLive: false,
      isPostLive: false, isLiveContent: false
    )
  }
}
