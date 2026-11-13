import XCTest
@testable import TypeTypeIOS

final class LiveAllowedChannelsServiceTests: XCTestCase {
  func testAddsTheChannelForEveryoneAndReadsTheList() async throws {
    let client = AllowListClient()
    let service = LiveAllowedChannelsService(apiClient: client)

    try await service.allowForEveryone(channelURL: "https://www.youtube.com/@a", name: "A", avatarURL: nil)
    let urls = try await service.allowedChannelURLs()

    XCTAssertEqual(urls, ["https://www.youtube.com/@a"])
    let sent = try XCTUnwrap(client.posted)
    XCTAssertEqual(sent["global"] as? Bool, true)
    XCTAssertEqual(sent["url"] as? String, "https://www.youtube.com/@a")
    XCTAssertEqual(sent["name"] as? String, "A")
  }
}

private final class AllowListClient: APIClient, @unchecked Sendable {
  var posted: [String: Any]?

  func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
    try JSONDecoder().decode(T.self, from: Data(#"[{"url":"https://www.youtube.com/@a","name":"A","global":true}]"#.utf8))
  }

  func request(_ endpoint: APIEndpoint) async throws {
    XCTAssertEqual(endpoint.path, "/allowed/channels")
    posted = try endpoint.body.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] }
  }

  func requestData(_ endpoint: APIEndpoint) async throws -> Data { Data() }
}
