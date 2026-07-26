import Foundation
import XCTest
@testable import TypeTypeIOS

final class SessionStoreTests: XCTestCase {
  func testPersistsRefreshesAndClearsAccessToken() {
    let suite = "SessionStoreTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else {
      XCTFail("Could not create test defaults.")
      return
    }
    defer {
      defaults.removePersistentDomain(forName: suite)
    }
    let keychain = MemoryKeychainService()
    let store = SessionStore(defaults: defaults, keychain: keychain)
    let snapshot = SessionSnapshot(
      serverID: "server-1",
      userID: "user-1",
      accountIdentifier: "person@example.test",
      role: "user"
    )

    store.saveSession(snapshot: snapshot, accessToken: "token-1")
    XCTAssertEqual(store.session(forServerID: "server-1"), snapshot)
    XCTAssertEqual(
      store.accessToken(forServerID: "server-1"),
      "token-1"
    )

    XCTAssertTrue(
      store.updateAccessToken("token-2", forServerID: "server-1")
    )
    XCTAssertEqual(
      store.accessToken(forServerID: "server-1"),
      "token-2"
    )

    store.clearSession(forServerID: "server-1")
    XCTAssertNil(store.session(forServerID: "server-1"))
    XCTAssertNil(store.accessToken(forServerID: "server-1"))
  }

  func testFreshSessionKeepsTokenInMemoryIfKeychainWriteFails() {
    let suite = "SessionStoreTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else {
      return XCTFail("Could not create test defaults.")
    }
    defer {
      defaults.removePersistentDomain(forName: suite)
    }
    let store = SessionStore(
      defaults: defaults,
      keychain: RefusingKeychainStub()
    )
    let snapshot = SessionSnapshot(
      serverID: "server-1",
      userID: "user-1",
      accountIdentifier: nil,
      role: "user"
    )

    store.saveSession(snapshot: snapshot, accessToken: "ephemeral")

    XCTAssertEqual(
      store.accessToken(forServerID: "server-1"),
      "ephemeral"
    )
    store.clearSession(forServerID: "server-1")
    XCTAssertNil(store.accessToken(forServerID: "server-1"))
  }
}

private final class RefusingKeychainStub: KeychainService {
  func set(_ value: String, for account: String) -> Bool {
    false
  }

  func get(_ account: String) -> String? {
    nil
  }

  func remove(_ account: String) -> Bool {
    true
  }
}

private final class MemoryKeychainService: KeychainService {
  private var values: [String: String] = [:]

  func set(_ value: String, for account: String) -> Bool {
    values[account] = value
    return true
  }

  func get(_ account: String) -> String? {
    values[account]
  }

  func remove(_ account: String) -> Bool {
    values.removeValue(forKey: account)
    return true
  }
}
