import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveDownloadCenterSavingTests: XCTestCase {
  private var rootURL: URL!

  override func setUp() {
    super.setUp()
    rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: rootURL)
    super.tearDown()
  }

  func testTransientSaveFailuresStopAfterBoundedRetries() async throws {
    let service = DownloadServiceStub(artifactFailuresRemaining: 100)
    let center = makeCenter(service)

    let record = try await center.start(
      video: LiveDownloadCenterDuplicateTests.video,
      options: LiveDownloadCenterDuplicateTests.videoOptions
    )
    try await waitUntil { center.activeTrackingCount == 0 }

    let failed = try XCTUnwrap(center.record(id: record.id))
    XCTAssertEqual(service.artifactAttempts, 5)
    XCTAssertEqual(failed.state, .failed)
    XCTAssertTrue(failed.state.canRetry)
    XCTAssertEqual(
      failed.failureMessage,
      "Download paused after 5 attempts. The network is unavailable; try again later."
    )
  }

  func testCancelWhileSavingDropsTheTransferAndRetrySavesAgain() async throws {
    let service = DownloadServiceStub(artifactDelay: .milliseconds(300))
    let center = makeCenter(service)
    let record = try await center.start(
      video: LiveDownloadCenterDuplicateTests.video,
      options: LiveDownloadCenterDuplicateTests.videoOptions
    )
    try await waitUntil { center.record(id: record.id)?.state == .saving }
    XCTAssertTrue(center.record(id: record.id)?.state.canCancel == true)

    try await center.cancel(id: record.id)
    try await Task.sleep(for: .milliseconds(400))

    let cancelled = try XCTUnwrap(center.record(id: record.id))
    XCTAssertEqual(cancelled.state, .cancelled)
    XCTAssertNil(center.artifactURL(for: cancelled))
    XCTAssertEqual(center.activeTrackingCount, 0)

    try await center.retry(id: record.id)
    try await waitUntil { center.record(id: record.id)?.state == .ready }
    XCTAssertNotNil(center.record(id: record.id).flatMap(center.artifactURL(for:)))
  }

  func testSavingProgressShowsOnlyWhileTheFileIsOnItsWay() async throws {
    let service = DownloadServiceStub(artifactDelay: .milliseconds(300), artifactProgress: 0.4)
    let center = makeCenter(service)
    let record = try await center.start(
      video: LiveDownloadCenterDuplicateTests.video,
      options: LiveDownloadCenterDuplicateTests.videoOptions
    )

    try await waitUntil { center.savingProgress[record.id] != nil }
    let saving = try XCTUnwrap(center.record(id: record.id))
    XCTAssertEqual(saving.state, .saving)
    XCTAssertEqual(center.progress(for: saving), 0.4)

    try await waitUntil { center.record(id: record.id)?.state == .ready }
    XCTAssertNil(center.savingProgress[record.id])
  }

  private func makeCenter(_ service: DownloadServiceStub) -> LiveDownloadCenter {
    let scope = LiveDownloadScope(serverID: "https://example.test", accountID: "account-1")
    return LiveDownloadCenter(
      service: service,
      scopeProvider: { scope },
      rootURL: rootURL,
      mediaValidator: AcceptingMediaValidator(),
      retryPolicy: LiveDownloadRetryPolicy(maxAttempts: 5, delays: [.zero])
    )
  }

  private func waitUntil(_ condition: () -> Bool) async throws {
    for _ in 0..<300 where !condition() {
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTAssertTrue(condition())
  }
}
