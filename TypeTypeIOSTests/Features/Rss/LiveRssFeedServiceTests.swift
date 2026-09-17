import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveRssFeedServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testCreateUsesAuthenticatedRssContract() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/rss/feeds")
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer test-token"
      )
      let body = try XCTUnwrap(URLProtocolStub.bodyData(from: request))
      let payload = try XCTUnwrap(
        JSONSerialization.jsonObject(with: body) as? [String: Any]
      )
      XCTAssertEqual(payload["name"] as? String, "All subscriptions")
      XCTAssertEqual(payload["scope"] as? String, "all")
      XCTAssertEqual(payload["serviceIds"] as? [Int], [0, 5, 6])
      return try Self.response(
        request,
        status: 201,
        body: """
        {
          "feed": {
            "id": "feed-1",
            "name": "All subscriptions",
            "scope": "all",
            "channelUrls": [],
            "serviceIds": [0, 5, 6],
            "includeVideos": true,
            "includeShorts": true,
            "includeLive": true,
            "includeUpcoming": true,
            "enabled": true,
            "createdAt": 1,
            "updatedAt": 2,
            "lastUsedAt": null
          },
          "feedUrl": "https://example.test/rss/feeds/feed-1.xml?token=secret"
        }
        """
      )
    }

    let secret = try await LiveRssFeedService(apiClient: Self.makeClient())
      .create(draft: Self.draft)

    XCTAssertEqual(secret.feed.id, "feed-1")
    XCTAssertEqual(
      secret.feedURL,
      "https://example.test/rss/feeds/feed-1.xml?token=secret"
    )
  }

  func testSetEnabledUsesRouteAndBody() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/rss/feeds/feed-1/enabled")
      XCTAssertEqual(request.httpMethod, "PUT")
      let body = try XCTUnwrap(URLProtocolStub.bodyData(from: request))
      let payload = try XCTUnwrap(
        JSONSerialization.jsonObject(with: body) as? [String: Any]
      )
      XCTAssertEqual(payload["enabled"] as? Bool, false)
      return try Self.response(
        request,
        status: 200,
        body: Self.feedJSON(enabled: false)
      )
    }

    let feed = try await LiveRssFeedService(apiClient: Self.makeClient())
      .setEnabled(id: "feed-1", enabled: false)

    XCTAssertFalse(feed.enabled)
  }

  private static func draft() -> LiveRssFeedDraft {
    LiveRssFeedDraft(
      name: "All subscriptions",
      scope: "all",
      channelURLs: [],
      serviceIDs: [0, 5, 6],
      includeVideos: true,
      includeShorts: true,
      includeLive: true,
      includeUpcoming: true
    )
  }

  private static func feedJSON(enabled: Bool) -> String {
    """
    {
      "id":"feed-1","name":"All subscriptions","scope":"all","channelUrls":[],
      "serviceIds":[0,5,6],"includeVideos":true,"includeShorts":true,
      "includeLive":true,"includeUpcoming":true,"enabled":\(enabled),
      "createdAt":1,"updatedAt":2,"lastUsedAt":null
    }
    """
  }

  private static func makeClient() -> URLSessionAPIClient {
    URLSessionAPIClient(
      serverURLProvider: { URL(string: "https://example.test/api") },
      accessTokenProvider: { "test-token" },
      session: Self.makeSession()
    )
  }

  private static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    _ request: URLRequest,
    status: Int,
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw TestError.missingURL
    }
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: url,
        statusCode: status,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, Data(body.utf8))
  }
}

private enum TestError: Error {
  case missingURL
}
