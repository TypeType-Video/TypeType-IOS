import XCTest
@testable import TypeTypeIOS

@MainActor
final class LivePresenceKeysViewModelTests: XCTestCase {
  func testCreatesAKeyShowsItsTokenOnceAndRevokesIt() async {
    let service = PresenceStub()
    let model = LivePresenceKeysViewModel(service: service)
    await model.load()
    XCTAssertFalse(model.canCreate)

    model.name = "  Discord RPC  "
    await model.create()
    XCTAssertEqual(service.names, ["Discord RPC"])
    XCTAssertEqual(model.createdToken, "ttp_secret")
    XCTAssertEqual(model.keys.map(\.name), ["Discord RPC"])
    XCTAssertEqual(model.name, "")

    await model.revoke(model.keys[0])
    XCTAssertTrue(model.keys.isEmpty)
    XCTAssertNil(model.createdToken)
  }
}

private final class PresenceStub: LivePresenceServiceProtocol, @unchecked Sendable {
  var names: [String] = []

  func keys() async throws -> [LivePresenceKey] { [] }

  func create(name: String) async throws -> LivePresenceKeyCreated {
    names.append(name)
    let json = #"{"key":{"id":"k1","name":"\#(name)","tokenPrefix":"ttp_","createdAt":1,"lastUsedAt":null},"token":"ttp_secret"}"#
    return try JSONDecoder().decode(LivePresenceKeyCreated.self, from: Data(json.utf8))
  }

  func revoke(id: String) async throws {}
}
