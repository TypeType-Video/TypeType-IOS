import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveSABRPlaybackSessionTests: XCTestCase {
  func testTransientSABRRetryPolicyMatchesAndroidClient() {
    XCTAssertEqual(
      LivePlaybackService.sabrRetryDelayMS(
        for: NetworkError.transport,
        failureCount: 1
      ),
      500
    )
    XCTAssertEqual(
      LivePlaybackService.sabrRetryDelayMS(
        for: NetworkError.statusCode(503, nil),
        failureCount: 4
      ),
      3_000
    )
    XCTAssertEqual(
      LivePlaybackService.sabrRetryDelayMS(
        for: NetworkError.statusCode(504, nil),
        failureCount: 24
      ),
      3_000
    )
    XCTAssertNil(
      LivePlaybackService.sabrRetryDelayMS(
        for: NetworkError.statusCode(429, nil),
        failureCount: 1
      )
    )
    XCTAssertNil(
      LivePlaybackService.sabrRetryDelayMS(
        for: NetworkError.transport,
        failureCount: 25
      )
    )
  }

  func testRecoveryPreservesSelectedH264Representation() async throws {
    let service = RecoveryPlaybackService()
    let session = LiveSABRPlaybackSession(
      service: service,
      preparation: preparation()
    )

    let snapshot = try await session.start()

    XCTAssertEqual(snapshot.video?.itag, 136)
    XCTAssertEqual(service.createdVideoItags, [136, 136])
    XCTAssertEqual(
      service.lifecycle,
      [
        "create", "position", "prefetch", "create",
        "position", "prefetch", "segments", "index",
      ]
    )
  }

  func testRecoveryUsesServerApprovedLowerH264Representation()
    async throws {
    let service = RecoveryPlaybackService(
      recoveryAction: "retry_fresh_session_lower_video_itag",
      retryVideoItags: [133]
    )
    let session = LiveSABRPlaybackSession(
      service: service,
      preparation: preparation()
    )

    let snapshot = try await session.start()

    XCTAssertEqual(snapshot.video?.itag, 133)
    XCTAssertEqual(service.createdVideoItags, [136, 133])
  }

  func testReportsPlaybackRateToTheActiveSABRSession() async throws {
    let service = RecoveryPlaybackService()
    let session = LiveSABRPlaybackSession(
      service: service,
      preparation: preparation()
    )
    _ = try await session.start()

    await session.updatePlaybackRate(2)

    XCTAssertEqual(service.positionRates.last, 2)
  }

  func testSeekRepositionsTheActiveSABRSession() async throws {
    let service = RecoveryPlaybackService()
    let session = LiveSABRPlaybackSession(
      service: service,
      preparation: preparation()
    )
    _ = try await session.start()

    let snapshot = try await session.seek(to: 300)

    XCTAssertEqual(service.seekTimes, [300_000])
    XCTAssertEqual(snapshot.sessionID, "recovered")
    XCTAssertEqual(snapshot.generation, 1)
    XCTAssertEqual(snapshot.startTimeMS, 300_000)
    XCTAssertEqual(snapshot.video?.startMS, 300_000)
  }

  private func preparation() -> LivePlaybackPreparation {
    let high = video(itag: 136, height: 720)
    let low = video(itag: 133, height: 240)
    let audio = LivePlaybackAudioSource(
      url: "",
      mimeType: "audio/mp4",
      bitrate: 128_000,
      codec: "mp4a.40.2",
      quality: "medium",
      itag: 140,
      audioTrackID: nil,
      audioTrackName: nil,
      audioLocale: nil,
      isOriginal: true,
      deliveryMethod: "SABR",
      manifestURL: nil
    )
    let stream = LivePlaybackStream(
      id: "video",
      title: "Video",
      uploaderName: "Channel",
      uploaderURL: "",
      uploaderAvatarURL: "",
      thumbnailURL: "",
      description: "",
      duration: 600,
      viewCount: 0,
      likeCount: 0,
      dislikeCount: 0,
      startPosition: 120,
      hlsURL: "",
      videoStreams: [],
      audioStreams: [audio],
      videoOnlyStreams: [high, low],
      subtitles: [],
      chapters: [],
      sponsorBlockSegments: [],
      relatedStreams: [],
      category: nil,
      isLive: false,
      isPostLive: false,
      isLiveContent: false
    )
    return LivePlaybackPreparation(
      stream: stream,
      assetURL: nil,
      usesAuthenticatedLoader: true,
      video: high,
      audio: audio,
      providerPlayback: nil,
      subtitles: [],
      resumeTime: 120,
      isSABR: true,
      audioOnly: false
    )
  }

  private func video(
    itag: Int,
    height: Int
  ) -> LivePlaybackVideoSource {
    LivePlaybackVideoSource(
      url: "",
      mimeType: "video/mp4",
      resolution: "\(height)p",
      bitrate: 1_000_000,
      codec: "avc1.4d401f",
      isVideoOnly: true,
      itag: itag,
      width: height * 16 / 9,
      height: height,
      fps: 30,
      deliveryMethod: "SABR",
      manifestURL: nil
    )
  }
}
