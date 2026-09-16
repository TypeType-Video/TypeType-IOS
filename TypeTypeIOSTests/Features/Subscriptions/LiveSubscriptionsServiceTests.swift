import XCTest
@testable import TypeTypeIOS

final class LiveSubscriptionsServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testListSubscribeAndUnsubscribeUseServerContract() async throws {
    var requests: [URLRequest] = []
    URLProtocolStub.register { request in
      requests.append(request)
      let body = """
      {"channelUrl":"https://youtube.test/channel","name":"Blender",\
      "avatarUrl":"https://image.test/avatar.jpg","subscribedAt":12}
      """
      switch request.httpMethod {
      case "GET":
        return try Self.response(request, status: 200, body: "[\(body)]")
      case "POST":
        return try Self.response(request, status: 201, body: body)
      default:
        return try Self.response(request, status: 204, body: "")
      }
    }
    let service = makeService()

    let subscriptions = try await service.subscriptions()
    let subscription = try await service.subscribe(
      channelURL: "https://youtube.test/channel",
      name: "Blender",
      avatarURL: "https://image.test/avatar.jpg"
    )
    try await service.unsubscribe(
      channelURL: "https://youtube.test/channel"
    )

    XCTAssertEqual(subscriptions.first?.name, "Blender")
    XCTAssertEqual(subscription.subscribedAt, 12)
    XCTAssertEqual(requests.map(\.httpMethod), ["GET", "POST", "DELETE"])
    XCTAssertEqual(
      URLComponents(
        url: try XCTUnwrap(requests.last?.url),
        resolvingAgainstBaseURL: false
      )?.queryItems,
      [
        URLQueryItem(
          name: "url",
          value: "https://youtube.test/channel"
        ),
      ]
    )
  }

  func testFeedRetriesPreparingResponseAndUsesOpaqueCursor() async throws {
    var requestCount = 0
    URLProtocolStub.register { request in
      requestCount += 1
      XCTAssertEqual(request.url?.path, "/api/subscriptions/feed")
      let query = URLComponents(
        url: try XCTUnwrap(request.url),
        resolvingAgainstBaseURL: false
      )?.queryItems
      XCTAssertTrue(
        query?.contains(
          URLQueryItem(name: "cursor", value: "opaque")
        ) == true
      )
      if requestCount == 1 {
        return try Self.response(
          request,
          status: 202,
          body: """
          {"code":"subscription_feed_preparing","retryAfterMs":1}
          """
        )
      }
      return try Self.response(
        request,
        status: 200,
        body: """
        {"videos":[],"nextpage":"next","generation":4,\
        "generatedAt":12,"refreshing":false}
        """
      )
    }

    let page = try await makeService().feed(nextPage: "opaque")

    XCTAssertEqual(requestCount, 2)
    XCTAssertEqual(page.nextPage, "next")
    XCTAssertEqual(page.generation, 4)
  }

  private func makeService() -> LiveSubscriptionsService {
    LiveSubscriptionsService(
      apiClient: URLSessionAPIClient(
        serverURLProvider: { URL(string: "https://example.test/api") },
        accessTokenProvider: { "token" },
        session: Self.session()
      )
    )
  }

  private static func session() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    _ request: URLRequest,
    status: Int,
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(request.url),
        statusCode: status,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, Data(body.utf8))
  }

  func testGroupContractUsesAuthenticatedRoutesAndFilter() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer token"
      )
      switch request.url?.path {
      case "/api/subscriptions/groups":
        if request.httpMethod == "GET" {
          return try Self.response(
            request,
            status: 200,
            body: Self.groupsJSON
          )
        }
        return try Self.response(
          request,
          status: 201,
          body: Self.groupJSON
        )
      case "/api/subscriptions/group-memberships":
        return try Self.response(request, status: 200, body: "[]")
      case "/api/subscriptions/feed":
        let query = URLComponents(
          url: try XCTUnwrap(request.url),
          resolvingAgainstBaseURL: false
        )?.queryItems
        XCTAssertTrue(
          query?.contains(
            URLQueryItem(
              name: "groupId",
              value: "11111111-1111-1111-1111-111111111111"
            )
          ) == true
        )
        return try Self.response(
          request,
          status: 200,
          body: """
          {"videos":[],"nextpage":null,"generation":1,\
          "generatedAt":2,"refreshing":false}
          """
        )
      default:
        XCTFail("Unexpected path: \(request.url?.path ?? "")")
        return try Self.response(request, status: 500, body: "")
      }
    }

    let service = makeService()
    let groups = try await service.groups()
    let memberships = try await service.memberships()
    _ = try await service.createGroup(name: "Kids")
    let page = try await service.feed(
      nextPage: nil,
      filter: .group(
        id: "11111111-1111-1111-1111-111111111111",
        name: "Kids"
      )
    )

    XCTAssertEqual(groups.first?.name, "Kids")
    XCTAssertTrue(memberships.isEmpty)
    XCTAssertNil(page.nextPage)
  }

  private static let groupsJSON = """
    [
      {
        "id": "11111111-1111-1111-1111-111111111111",
        "name": "Kids",
        "channelCount": 2,
        "createdAt": 1,
        "updatedAt": 2
      }
    ]
    """

  private static let groupJSON = """
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "name": "Kids",
      "channelCount": 0,
      "createdAt": 1,
      "updatedAt": 2
    }
    """
}
