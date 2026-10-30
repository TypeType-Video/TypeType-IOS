import CryptoKit
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

  func testCancelTrackingClearsIdentityScopedWork() async throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let scope = LiveDownloadScope(
      serverID: "https://example.test",
      accountID: "account-1"
    )
    let center = LiveDownloadCenter(
      service: DownloadServiceStub(),
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )

    _ = try await center.start(
      video: Self.video,
      options: Self.options
    )
    XCTAssertEqual(center.activeTrackingCount, 1)

    center.cancelTracking()
    XCTAssertEqual(center.activeTrackingCount, 0)
    XCTAssertNil(center.activeScope)
  }

  func testTransientDownloadRefreshesStopAfterBoundedRetries()
    async throws
  {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let scope = LiveDownloadScope(
      serverID: "https://example.test",
      accountID: "account-1"
    )
    let service = DownloadServiceStub(jobFailuresRemaining: 100)
    let center = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator(),
      retryPolicy: LiveDownloadRetryPolicy(
        maxAttempts: 5,
        delays: [.zero, .zero, .zero, .zero]
      )
    )

    let record = try await center.start(
      video: Self.video,
      options: Self.options
    )

    for _ in 0..<100 where center.activeTrackingCount != 0 {
      try await Task.sleep(for: .milliseconds(5))
    }

    XCTAssertEqual(service.jobAttempts, 5)
    XCTAssertEqual(center.activeTrackingCount, 0)
    XCTAssertEqual(center.record(id: record.id)?.state, .failed)
    XCTAssertEqual(
      center.record(id: record.id)?.failureMessage,
      "Download paused after 5 attempts. The network is unavailable; try again later."
    )
    XCTAssertTrue(center.record(id: record.id)?.state.canRetry == true)
  }

  func testDownloadChecksumIsPersistedAndVerifiedOnRestore()
    async throws
  {
    let context = try await makeCompletedDownloadContext()
    let record = try XCTUnwrap(
      context.center.record(id: context.record.id)
    )
    let expectedChecksum = SHA256.hash(data: Data("offline-media".utf8))
      .map { String(format: "%02x", $0) }
      .joined()

    XCTAssertEqual(record.artifactChecksum, expectedChecksum)
    XCTAssertEqual(
      context.restoredCenter.record(id: record.id)?.state,
      .ready
    )
    XCTAssertEqual(
      context.restoredCenter.record(id: record.id)?.artifactChecksum,
      expectedChecksum
    )
  }

  func testCorruptedDownloadChecksumFailsOnRestore() async throws {
    let context = try await makeCompletedDownloadContext()
    let record = try XCTUnwrap(
      context.center.record(id: context.record.id)
    )
    let artifactURL = try XCTUnwrap(
      context.center.artifactURL(for: record)
    )

    try Data("corrupted-media".utf8).write(to: artifactURL)
    let restored = LiveDownloadCenter(
      service: context.service,
      scopeProvider: { context.scope },
      rootURL: context.rootURL,
      mediaValidator: AcceptingMediaValidator()
    )
    await restored.verifyArtifacts()

    let restoredRecord = try XCTUnwrap(
      restored.record(id: record.id)
    )
    XCTAssertEqual(restoredRecord.state, .failed)
    XCTAssertEqual(
      restoredRecord.failureMessage,
      "The downloaded file no longer matches its integrity checksum."
    )
  }

  func testRestoreMigratesLegacyDownloadsWithChecksums() async throws {
    let context = try await makeCompletedDownloadContext()
    let record = try XCTUnwrap(
      context.center.record(id: context.record.id)
    )
    context.center.records[0].artifactChecksum = nil
    context.center.persist()

    let restored = LiveDownloadCenter(
      service: context.service,
      scopeProvider: { context.scope },
      rootURL: context.rootURL,
      mediaValidator: AcceptingMediaValidator()
    )
    await restored.verifyArtifacts()
    let restoredRecord = try XCTUnwrap(
      restored.record(id: record.id)
    )
    XCTAssertEqual(restoredRecord.state, .ready)
    XCTAssertNotNil(restoredRecord.artifactChecksum)
  }

  func testStorageUsageCountsSavedArtifacts() async throws {
    let context = try await makeCompletedDownloadContext()
    await context.center.refreshStorageUsage()

    XCTAssertEqual(context.center.storageUsage, Int64(Data("offline-media".utf8).count))
  }

  func testRestoreRemovesOrphanedArtifacts() async throws {
    let context = try await makeCompletedDownloadContext()
    let orphanURL = context.center.artifactsURL
      .appendingPathComponent("orphan.bin")
    try Data("orphan".utf8).write(to: orphanURL)

    _ = LiveDownloadCenter(
      service: context.service,
      scopeProvider: { context.scope },
      rootURL: context.rootURL,
      mediaValidator: AcceptingMediaValidator()
    )

    XCTAssertFalse(
      context.center.fileManager.fileExists(atPath: orphanURL.path)
    )
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

  private func makeCompletedDownloadContext() async throws -> (
    center: LiveDownloadCenter,
    restoredCenter: LiveDownloadCenter,
    service: DownloadServiceStub,
    scope: LiveDownloadScope,
    rootURL: URL,
    record: LiveManagedDownload
  ) {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
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
    let record = try await center.start(
      video: Self.video,
      options: Self.options
    )
    await center.refresh()
    let restored = LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator()
    )
    return (
      center,
      restored,
      service,
      scope,
      rootURL,
      record
    )
  }
}
