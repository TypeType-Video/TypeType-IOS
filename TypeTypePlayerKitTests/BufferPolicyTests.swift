import XCTest
@testable import TypeTypePlayerKit

final class BufferPolicyTests: XCTestCase {
  func testGoalFollowsTheWebPlayer() {
    XCTAssertEqual(BufferPolicy.goal(10, rate: 1), 10)
    XCTAssertEqual(BufferPolicy.goal(10, rate: 0.5), 10)
    XCTAssertEqual(BufferPolicy.goal(10, rate: 2), 20)
    XCTAssertEqual(BufferPolicy.goal(10, rate: 8), 60)
  }

  func testRefillWaitsForTwoThirdsWithAFiveSecondFloor() {
    XCTAssertEqual(BufferPolicy.refillThreshold(goal: 10), 20.0 / 3, accuracy: 0.001)
    XCTAssertEqual(BufferPolicy.refillThreshold(goal: 6), 5)
    XCTAssertEqual(BufferPolicy.refillThreshold(goal: 4), 4)
    XCTAssertEqual(BufferPolicy.refillThreshold(goal: 60), 40)
  }
}
