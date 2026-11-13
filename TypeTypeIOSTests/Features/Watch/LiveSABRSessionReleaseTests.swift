import XCTest
@testable import TypeTypeIOS

final class LiveSABRSessionReleaseTests: XCTestCase {
  func testRecoveryReleasesTheSessionItReplaces() async throws {
    let service = RecoveryPlaybackService()
    let session = LiveSABRPlaybackSession(service: service, preparation: LiveSABRPlaybackSessionTests.preparation())

    _ = try await session.start()
    await waitForReleases(service, count: 1)

    XCTAssertEqual(service.releasedSessionIDs, ["initial"])
  }

  func testReleaseFreesTheActiveSessionOnce() async throws {
    let service = RecoveryPlaybackService()
    let session = LiveSABRPlaybackSession(service: service, preparation: LiveSABRPlaybackSessionTests.preparation())
    _ = try await session.start()
    await waitForReleases(service, count: 1)

    await session.release()
    await session.release()

    XCTAssertEqual(service.releasedSessionIDs, ["initial", "recovered"])
  }

  func testReleasedSessionNeverOpensAnother() async {
    let service = RecoveryPlaybackService()
    let session = LiveSABRPlaybackSession(service: service, preparation: LiveSABRPlaybackSessionTests.preparation())
    await session.release()

    do {
      _ = try await session.start()
      XCTFail("a released session started")
    } catch {
      XCTAssertTrue(error is CancellationError)
    }
    XCTAssertEqual(service.createdVideoItags, [])
    XCTAssertEqual(service.releasedSessionIDs, [])
  }

  private func waitForReleases(_ service: RecoveryPlaybackService, count: Int) async {
    for _ in 0..<200 where service.releasedSessionIDs.count < count {
      try? await Task.sleep(for: .milliseconds(10))
    }
  }
}
