import XCTest
@testable import TypeTypeIOS

final class LiveSABRMaintenanceFailureBudgetTests: XCTestCase {
  func testBudgetAllowsFiveBackedOffAttempts() {
    XCTAssertEqual(
      LiveSABRPlaybackSession.maximumMaintenanceFailures,
      5
    )
    XCTAssertFalse(
      LiveSABRPlaybackSession.shouldStopMaintenance(failureCount: 4)
    )
    XCTAssertTrue(
      LiveSABRPlaybackSession.shouldStopMaintenance(failureCount: 5)
    )
  }

  func testMaintenanceBudgetStaysWithinOneMinuteOfTotalDelay() {
    let delays = (1...LiveSABRPlaybackSession.maximumMaintenanceFailures)
      .map { failureIndex in
        LiveSABRPlaybackSession.maintenanceRetryDelayMS(
          failureCount: failureIndex
        )
      }

    XCTAssertEqual(
      delays.reduce(0, +),
      60_000
    )
  }
}
