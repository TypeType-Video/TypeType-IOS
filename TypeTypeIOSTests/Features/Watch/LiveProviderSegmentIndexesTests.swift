import TypeTypePlayerKit
import XCTest
@testable import TypeTypeIOS

final class LiveProviderSegmentIndexesTests: XCTestCase {
  func testFailedIndexLoadIsAskedAgain() async throws {
    let attempts = AttemptCounter()
    let indexes = LiveProviderSegmentIndexes(kinds: []) { _ in
      if attempts.next() == 1 { throw URLError(.notConnectedToInternet) }
      return []
    }

    do {
      _ = try await indexes.entries(.video)
      XCTFail("The first load fails.")
    } catch {}
    let entries = try await indexes.entries(.video)

    XCTAssertEqual(entries, [])
    XCTAssertEqual(attempts.value, 2)
  }

  func testLoadedIndexIsKept() async throws {
    let attempts = AttemptCounter()
    let indexes = LiveProviderSegmentIndexes(kinds: []) { _ in
      _ = attempts.next()
      return []
    }

    _ = try await indexes.entries(.audio)
    _ = try await indexes.entries(.audio)

    XCTAssertEqual(attempts.value, 1)
  }
}

private final class AttemptCounter: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0

  var value: Int { lock.withLock { count } }

  func next() -> Int {
    lock.withLock {
      count += 1
      return count
    }
  }
}
