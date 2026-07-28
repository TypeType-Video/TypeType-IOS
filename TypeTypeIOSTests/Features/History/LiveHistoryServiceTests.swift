import XCTest
@testable import TypeTypeIOS

final class LiveHistoryServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testHistoryUsesSearchDateAndPaginationContract() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/history")
      let query = URLComponents(
        url: try XCTUnwrap(request.url),
        resolvingAgainstBaseURL: false
      )?.queryItems ?? []
      XCTAssertTrue(query.contains(URLQueryItem(name: "q", value: "bunny")))
      XCTAssertTrue(query.contains(URLQueryItem(name: "from", value: "10")))
      XCTAssertTrue(query.contains(URLQueryItem(name: "to", value: "20")))
      XCTAssertTrue(query.contains(URLQueryItem(name: "limit", value: "30")))
      XCTAssertTrue(query.contains(URLQueryItem(name: "offset", value: "60")))
      return try Self.response(
        request,
        status: 200,
        body: """
        [{
          "id":"history-1","url":"https://video.test/1","title":"Bunny",
          "thumbnail":"","channelName":"Blender","channelUrl":"",
          "channelAvatar":"","duration":120,"progress":42,
          "watchedAt":1785063770906
        }]
        """
      )
    }

    let items = try await makeService().history(
      query: "bunny",
      from: 10,
      to: 20,
      limit: 30,
      offset: 60
    )

    XCTAssertEqual(items.first?.title, "Bunny")
    XCTAssertEqual(items.first?.progressFraction, 0.35)
  }

  func testRemoveAndClearUseDeleteRoutes() async throws {
    var requests: [URLRequest] = []
    URLProtocolStub.register { request in
      requests.append(request)
      return try Self.response(request, status: 204, body: "")
    }
    let service = makeService()

    try await service.remove(id: "history-1")
    try await service.clear()

    XCTAssertEqual(requests.map(\.httpMethod), ["DELETE", "DELETE"])
    XCTAssertEqual(requests[0].url?.path, "/api/history/history-1")
    XCTAssertEqual(requests[1].url?.path, "/api/history")
  }

  func testProgressReadsMillisecondsFromProgressRoute() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/progress")
      XCTAssertEqual(
        URLComponents(
          url: try XCTUnwrap(request.url),
          resolvingAgainstBaseURL: false
        )?.queryItems,
        [
          URLQueryItem(
            name: "url",
            value: "https://www.youtube.com/watch?v=mcV4qoX2MIE"
          )
        ]
      )
      return try Self.response(
        request,
        status: 200,
        body: #"{"position":120000}"#
      )
    }

    let positionMS = try await makeService().progress(
      videoURL: "https://www.youtube.com/watch?v=mcV4qoX2MIE"
    )

    XCTAssertEqual(positionMS, 120_000)
  }

  func testMissingProgressReturnsNil() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(request.url?.path, "/api/progress")
      return try Self.response(
        request,
        status: 404,
        body: #"{"error":"not found"}"#
      )
    }

    let positionMS = try await makeService().progress(
      videoURL: "https://www.youtube.com/watch?v=iYlODtkyw_I"
    )

    XCTAssertNil(positionMS)
  }

  func testProgressUpdateWritesMillisecondsWithoutConversion() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.httpMethod, "PUT")
      XCTAssertEqual(request.url?.path, "/api/progress")
      XCTAssertEqual(
        try XCTUnwrap(URLProtocolStub.bodyData(from: request)),
        Data(#"{"position":42500}"#.utf8)
      )
      return try Self.response(request, status: 204, body: "")
    }

    try await makeService().updateProgress(
      videoURL: "https://www.youtube.com/watch?v=zzjq7_ddb0U",
      positionMS: 42_500
    )
  }

  private func makeService() -> LiveHistoryService {
    LiveHistoryService(
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
}
