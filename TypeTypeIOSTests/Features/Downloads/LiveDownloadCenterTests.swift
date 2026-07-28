import Foundation
import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveDownloadCenterTests: XCTestCase {
  func testCompletedDownloadIsSavedLocallyAndRestored() async throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let scope = LiveDownloadScope(
      serverID: "https://example.test",
      accountID: "account-1"
    )
    let service = DownloadServiceStub()
    let center = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )

    let started = try await center.start(
      video: Self.video,
      options: Self.options
    )

    XCTAssertEqual(started.state, .queued)
    await center.refresh()

    let completed = try XCTUnwrap(center.visibleRecords.first)
    XCTAssertEqual(completed.state, .ready)
    let artifactURL = try XCTUnwrap(
      center.artifactURL(for: completed)
    )
    XCTAssertEqual(
      try Data(contentsOf: artifactURL),
      Data("offline-media".utf8)
    )

    let restored = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )
    let restoredRecord = try XCTUnwrap(restored.visibleRecords.first)
    XCTAssertEqual(restoredRecord.state, .ready)
    XCTAssertNotNil(restored.artifactURL(for: restoredRecord))
  }

  func testRecordsAreIsolatedByServerAndAccount() async throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    var scope = LiveDownloadScope(
      serverID: "https://one.example",
      accountID: "account-1"
    )
    let center = LiveDownloadCenter(
      service: DownloadServiceStub(),
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )

    _ = try await center.start(video: Self.video, options: Self.options)
    XCTAssertEqual(center.visibleRecords.count, 1)

    scope = LiveDownloadScope(
      serverID: "https://one.example",
      accountID: "account-2"
    )
    await center.activate()
    XCTAssertTrue(center.visibleRecords.isEmpty)
  }

  func testTransientArtifactFailureWaitsAndResumesSaving()
    async throws
  {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let scope = LiveDownloadScope(
      serverID: "https://example.test",
      accountID: "account-1"
    )
    let service = DownloadServiceStub(
      artifactFailuresRemaining: 1
    )
    let center = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )

    _ = try await center.start(
      video: Self.video,
      options: Self.options
    )
    await center.refresh()

    let waiting = try XCTUnwrap(center.visibleRecords.first)
    XCTAssertEqual(waiting.state, .saving)
    XCTAssertEqual(
      waiting.failureMessage,
      "Waiting for the network to finish saving this download."
    )
    XCTAssertNil(center.artifactURL(for: waiting))

    await center.refresh()

    let recovered = try XCTUnwrap(center.visibleRecords.first)
    XCTAssertEqual(recovered.state, .ready)
    XCTAssertNil(recovered.failureMessage)
    XCTAssertNotNil(center.artifactURL(for: recovered))
    XCTAssertEqual(service.artifactAttempts, 2)
  }

  func testDownloadSheetDefaultsRequestNativePlayableMedia()
    async throws
  {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let scope = LiveDownloadScope(
      serverID: "https://example.test",
      accountID: "account-1"
    )
    let service = DownloadServiceStub()
    let center = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )
    let videoViewModel = LiveDownloadViewModel(
      video: Self.video,
      center: center
    )

    await videoViewModel.start()

    let video = try XCTUnwrap(service.createdOptions.first)
    XCTAssertEqual(video.format, "mp4")
    XCTAssertEqual(video.height, 1_080)
    XCTAssertEqual(video.videoCodec, "h264")
    XCTAssertEqual(video.audioCodec, "aac")

    let audioViewModel = LiveDownloadViewModel(
      video: Self.video,
      center: center
    )
    audioViewModel.mode = .audio
    await audioViewModel.start()

    let audio = try XCTUnwrap(service.createdOptions.last)
    XCTAssertEqual(audio.format, "m4a")
    XCTAssertNil(audio.height)
    XCTAssertNil(audio.videoCodec)
    XCTAssertEqual(audio.audioCodec, "aac")
  }

  func testConcurrentRefreshesSaveOneArtifact() async throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let scope = LiveDownloadScope(
      serverID: "https://example.test",
      accountID: "account-1"
    )
    let service = DownloadServiceStub(
      artifactDelay: .milliseconds(100)
    )
    let center = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )
    _ = try await center.start(
      video: Self.video,
      options: Self.options
    )

    async let first: Void = center.refresh()
    async let second: Void = center.refresh()
    _ = await (first, second)

    XCTAssertEqual(service.artifactAttempts, 1)
    XCTAssertEqual(center.visibleRecords.first?.state, .ready)
  }

  private static let video = LiveVideoItem(
    id: "mcV4qoX2MIE",
    title: "Download test",
    url: "https://www.youtube.com/watch?v=mcV4qoX2MIE",
    thumbnailURL: "",
    uploaderName: "TypeType",
    uploaderURL: "",
    uploaderAvatarURL: "",
    duration: 120,
    viewCount: 1,
    uploadDate: "",
    uploaded: 0,
    streamType: "VIDEO_STREAM",
    isShortFormContent: false,
    uploaderVerified: false,
    shortDescription: nil,
    publishedAt: nil,
    isLive: false,
    isPostLive: false,
    isLiveContent: false,
    requiresMembership: false
  )

  private static let options = LiveDownloadOptions(
    mode: "video",
    quality: "1080p",
    format: "mp4",
    allowQualityFallback: true,
    sponsorBlock: true,
    sponsorBlockCategories: ["sponsor"],
    thumbnailOnly: false,
    subtitles: LiveDownloadSubtitleOptions(
      enabled: false,
      auto: false,
      embed: false,
      languages: [],
      format: "vtt"
    )
  )
}
