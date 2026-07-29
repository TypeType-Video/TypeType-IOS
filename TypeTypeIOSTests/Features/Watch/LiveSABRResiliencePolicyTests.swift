import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveSABRResiliencePolicyTests: XCTestCase {
  func testLiveRetentionDropsExpiredBackBuffer() {
    let segments = (1...8).map {
      segment(sequence: $0, startMS: Int64(($0 - 1) * 10_000))
    }

    let retained = LiveSABRPlaybackSession.retainedLiveSegments(
      segments,
      playerTimeMS: 70_000,
      seekableStartMS: 30_000
    )

    XCTAssertEqual(retained.map(\.sequence), [4, 5, 6, 7, 8])
  }

  func testLiveRetentionAlwaysKeepsTheNewestSegment() {
    let segments = [
      segment(sequence: 1, startMS: 0),
      segment(sequence: 2, startMS: 10_000),
    ]

    let retained = LiveSABRPlaybackSession.retainedLiveSegments(
      segments,
      playerTimeMS: 300_000,
      seekableStartMS: 250_000
    )

    XCTAssertEqual(retained.map(\.sequence), [2])
  }

  func testMaintenanceBackoffIsBounded() {
    XCTAssertEqual(
      LiveSABRPlaybackSession.maintenanceRetryDelayMS(
        failureCount: 0
      ),
      1_000
    )
    XCTAssertEqual(
      LiveSABRPlaybackSession.maintenanceRetryDelayMS(
        failureCount: 4
      ),
      16_000
    )
    XCTAssertEqual(
      LiveSABRPlaybackSession.maintenanceRetryDelayMS(
        failureCount: 20
      ),
      30_000
    )
  }

  func testActiveLivePlaylistUsesSlidingWindowSemantics()
    throws {
    let track = LiveSABRTrackSnapshot(
      itag: 140,
      mime: "audio/mp4",
      initURL: URL(
        string: "https://example.test/sabr/140/init"
      )!,
      segments: [
        segment(sequence: 41, startMS: 400_000),
        segment(sequence: 42, startMS: 410_000),
      ]
    )
    let snapshot = LiveSABRPlaybackSnapshot(
      sessionID: "session",
      generation: 0,
      startTimeMS: 400_000,
      durationMS: 420_000,
      endOfStream: false,
      audio: track,
      video: nil,
      live: LiveSABRLiveState(
        active: true,
        postLiveDVR: false,
        headSequence: 42,
        headTimeMS: 420_000,
        seekableStartMS: 300_000,
        seekableEndMS: 420_000,
        atLiveEdge: true,
        targetLatencyMS: 20_000
      ),
      index: nil
    )

    let playlist = try XCTUnwrap(
      String(
        data: LiveSABRPlaylistBuilder.media(
          track: track,
          snapshot: snapshot,
          kind: .audio
        ),
        encoding: .utf8
      )
    )

    XCTAssertTrue(playlist.contains("#EXT-X-MEDIA-SEQUENCE:41"))
    XCTAssertFalse(playlist.contains("#EXT-X-PLAYLIST-TYPE:EVENT"))
  }

  private func segment(
    sequence: Int,
    startMS: Int64
  ) -> LiveSABRMediaSegment {
    LiveSABRMediaSegment(
      url: URL(
        string: "https://example.test/sabr/140/segment/\(sequence)"
      )!,
      startMS: startMS,
      durationMS: 10_000
    )
  }
}
