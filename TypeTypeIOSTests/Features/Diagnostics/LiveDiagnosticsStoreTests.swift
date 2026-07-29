import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveDiagnosticsStoreTests: XCTestCase {
  func testBatchesPersistenceWithoutHidingPendingEntries() async throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let scope = LiveDiagnosticScope(
      serverID: "server",
      accountID: "account"
    )
    let store = LiveDiagnosticsStore(
      rootURL: rootURL,
      persistenceDelay: .milliseconds(20)
    )
    let baseURL = try XCTUnwrap(
      URL(string: "https://example.test/api")
    )

    for index in 0..<20 {
      await store.record(
        scope: scope,
        method: "GET",
        requestURL: baseURL.appendingPathComponent(
          "sabr/playback/session/segments"
        ),
        baseURL: baseURL,
        statusCode: 200,
        durationMilliseconds: Int64(index),
        requestID: "request-\(index)"
      )
    }

    let pending = await store.entries(for: scope)
    XCTAssertEqual(pending.count, 20)
    try await Task.sleep(for: .milliseconds(100))

    let restoredStore = LiveDiagnosticsStore(rootURL: rootURL)
    let restored = await restoredStore.entries(for: scope)
    XCTAssertEqual(restored.count, 20)
    XCTAssertEqual(restored.first?.requestID, "request-19")
  }
}
