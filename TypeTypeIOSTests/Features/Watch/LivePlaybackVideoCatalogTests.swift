import XCTest
@testable import TypeTypeIOS

final class LivePlaybackVideoCatalogTests: XCTestCase {
  private func source(
    itag: Int,
    height: Int,
    bitrate: Int?,
    codec: String = "avc1.640028",
    fps: Int = 30
  ) -> LivePlaybackVideoSource {
    LivePlaybackVideoSource(
      url: "https://example.test/\(itag)",
      mimeType: "video/mp4",
      resolution: "\(height)p",
      bitrate: bitrate,
      codec: codec,
      isVideoOnly: true,
      itag: itag,
      width: height * 16 / 9,
      height: height,
      fps: fps,
      contentLength: 1,
      initStart: 0,
      initEnd: 0,
      indexStart: 0,
      indexEnd: 0,
      deliveryMethod: "progressive",
      manifestURL: nil
    )
  }

  func testResolutionOptionsKeepTheHighestBitrateVariant() {
    let options = LivePlaybackVideoCatalog.resolutionOptions(from: [
      source(itag: 1, height: 360, bitrate: 300_000),
      source(itag: 2, height: 360, bitrate: 700_000),
      source(itag: 3, height: 720, bitrate: 2_000_000),
      source(itag: 4, height: 0, bitrate: 9_000_000),
    ])

    XCTAssertEqual(options.map(\.height), [360, 720])
    XCTAssertEqual(options.map(\.itag), [2, 3])
  }

  func testQualityAndDetailLabelsExposeFpsCodecAndBitrate() {
    let variant = source(
      itag: 5,
      height: 1080,
      bitrate: 4_500_000,
      fps: 60
    )

    XCTAssertEqual(
      LivePlaybackVideoCatalog.qualityLabel(for: variant),
      "1080p60"
    )
    XCTAssertEqual(
      LivePlaybackVideoCatalog.detailLabel(for: variant),
      "1080p60 · H.264 · 4.5 Mbps"
    )
  }

  func testUnknownCodecIsPassedThroughWithoutSyntheticLabel() {
    let variant = source(
      itag: 6,
      height: 480,
      bitrate: nil,
      codec: "example"
    )

    XCTAssertEqual(
      LivePlaybackVideoCatalog.codecLabel(for: variant),
      "example"
    )
    XCTAssertEqual(
      LivePlaybackVideoCatalog.detailLabel(for: variant),
      "480p · example"
    )
  }
}
