import XCTest
@testable import TypeTypeIOS

final class LiveDownloadRetryPolicyTests: XCTestCase {
  func testStandardPolicyUsesBoundedBackoff() {
    let policy = LiveDownloadRetryPolicy.standard

    XCTAssertEqual(policy.delayBeforeAttempt(1), .milliseconds(1_500))
    XCTAssertEqual(policy.delayBeforeAttempt(2), .seconds(3))
    XCTAssertEqual(policy.delayBeforeAttempt(3), .seconds(6))
    XCTAssertEqual(policy.delayBeforeAttempt(4), .seconds(12))
    XCTAssertEqual(policy.delayBeforeAttempt(5), .seconds(12))
    XCTAssertNil(policy.delayBeforeAttempt(6))
  }
}
