import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveTypeTypeRestoreOperationStoreTests: XCTestCase {
  func testOperationPersistsLoadsAndClears() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let store = LiveTypeTypeRestoreOperationStore(directory: directory)
    defer {
      try? FileManager.default.removeItem(at: directory)
    }
    let sourceURL = directory.appendingPathComponent("source.json")
    let operation = LiveTypeTypeRestoreOperation(
      sourceURL: sourceURL,
      originalName: "typetype-backup.json",
      categories: ["history", "settings"],
      phase: .uploading
    )

    XCTAssertNil(store.load())
    try store.save(operation)

    XCTAssertEqual(store.load(), operation)
    XCTAssertTrue(
      FileManager.default.fileExists(atPath: store.operationURL.path)
    )

    store.clear(operation)

    XCTAssertNil(store.load())
    XCTAssertFalse(FileManager.default.fileExists(atPath: sourceURL.path))
  }
}
