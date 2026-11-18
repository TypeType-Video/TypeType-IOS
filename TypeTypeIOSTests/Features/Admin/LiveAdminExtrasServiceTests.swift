import XCTest
@testable import TypeTypeIOS

final class LiveAdminExtrasServiceTests: XCTestCase {
  func testSendsTheNoticeAndPagesTheFeeds() async throws {
    let client = CapturingClient()
    let service = LiveAdminExtrasService(apiClient: client)

    try await service.announce(LiveAdminNoticeRequest(kind: "maintenance", message: "Back soon", resumeInSeconds: nil))
    XCTAssertEqual(client.endpoints.last?.path, "/admin/server/notice")
    XCTAssertEqual(client.endpoints.last?.method, .post)
    let body = try XCTUnwrap(client.endpoints.last?.body.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
    XCTAssertEqual(body["kind"] as? String, "maintenance")

    let page = try await service.rssFeeds(page: 2, limit: 30)
    XCTAssertEqual(page.total, 1)
    XCTAssertEqual(client.endpoints.last?.queryItems.first { $0.name == "page" }?.value, "2")
  }
}

private final class CapturingClient: APIClient, @unchecked Sendable {
  var endpoints: [APIEndpoint] = []

  func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
    endpoints.append(endpoint)
    let json = #"{"items":[{"feed":{"id":"f","name":"Feed","enabled":true,"lastUsedAt":null},"userId":"u","userName":"User","userRssEnabled":true,"userSuspended":false}],"page":2,"limit":30,"total":1}"#
    return try JSONDecoder().decode(T.self, from: Data(json.utf8))
  }

  func request(_ endpoint: APIEndpoint) async throws { endpoints.append(endpoint) }

  func requestData(_ endpoint: APIEndpoint) async throws -> Data {
    endpoints.append(endpoint)
    return Data("{}".utf8)
  }
}
