import XCTest
@testable import TypeTypeIOS

@MainActor
final class LiveNotificationCenterPollingTests: XCTestCase {
  func testPollingRefreshesBadgeUntilCancelled() async throws {
    let service = UnreadCountServiceStub(
      values: [1, 4, 7, 9],
      errorAfter: 3
    )
    let center = LiveNotificationCenter(service: service)

    center.startPolling(interval: .milliseconds(10))
    try await Task.sleep(for: .milliseconds(80))
    center.stopPolling()
    let attemptsAfterStop = service.attempts
    try await Task.sleep(for: .milliseconds(30))

    XCTAssertFalse(center.isPolling)
    XCTAssertGreaterThanOrEqual(attemptsAfterStop, 3)
    XCTAssertEqual(service.attempts, attemptsAfterStop)
    XCTAssertEqual(center.unreadCount, 7)
  }

  func testPollingDoesNotRunTwiceConcurrently() async throws {
    let service = UnreadCountServiceStub(values: [2, 5])
    let center = LiveNotificationCenter(service: service)

    center.startPolling(interval: .milliseconds(20))
    try await Task.sleep(for: .milliseconds(30))
    center.startPolling(interval: .milliseconds(20))

    XCTAssertGreaterThanOrEqual(service.attempts, 1)
    center.stopPolling()
    let attemptsAfterStop = service.attempts
    try await Task.sleep(for: .milliseconds(30))
    XCTAssertEqual(service.attempts, attemptsAfterStop)
    XCTAssertFalse(center.isPolling)
  }
}

private final class UnreadCountServiceStub: LiveNotificationsServiceProtocol {
  private let lock = NSLock()
  private let values: [Int]
  private let errorAfter: Int?
  private var requestCount = 0

  init(
    values: [Int],
    errorAfter: Int? = nil
  ) {
    self.values = values
    self.errorAfter = errorAfter
  }

  var attempts: Int {
    lock.withLock { requestCount }
  }

  func unreadCount() async throws -> Int {
    let index: Int = lock.withLock {
      requestCount += 1
      return requestCount
    }
    if let errorAfter, index > errorAfter {
      throw NetworkError.transport
    }
    return values[min(index - 1, values.count - 1)]
  }

  func notifications(
    page: Int,
    limit: Int
  ) async throws -> LiveNotificationsPage {
    throw NetworkError.invalidResponse
  }

  func markAllRead() async throws -> LiveNotificationsReadResult {
    throw NetworkError.invalidResponse
  }

  func markRead(
    notificationID: String
  ) async throws -> LiveNotificationsReadResult {
    throw NetworkError.invalidResponse
  }
}
