import Foundation
import XCTest
@testable import TypeTypeIOS

final class ServerStoreTests: XCTestCase {
  private var defaults: UserDefaults!
  private var suiteName: String!

  override func setUp() {
    super.setUp()
    suiteName = "ServerStoreTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    defaults = nil
    suiteName = nil
    super.tearDown()
  }

  func testNormalizesDomainToAPIBaseAndSelectsIt() throws {
    let store = ServerStore(defaults: defaults)
    let server = try store.makeServer(
      name: "",
      urlInput: "beta.typetype.video/"
    )

    XCTAssertEqual(
      server.baseURLString,
      "https://beta.typetype.video/api"
    )
    XCTAssertEqual(server.name, "beta.typetype.video")

    try store.insert(server)
    XCTAssertEqual(store.selectedServerID(), server.id)
    XCTAssertEqual(store.selectedServer(), server)
  }

  func testRejectsCredentialsAndDuplicateInstances() throws {
    let store = ServerStore(defaults: defaults)
    XCTAssertThrowsError(
      try store.makeServer(
        name: "Unsafe",
        urlInput: "https://user:secret@example.test"
      )
    )

    let server = try store.makeServer(
      name: "One",
      urlInput: "https://example.test"
    )
    try store.insert(server)
    XCTAssertThrowsError(
      try store.insert(
        try store.makeServer(
          name: "Duplicate",
          urlInput: "https://example.test"
        )
      )
    )
  }
}
