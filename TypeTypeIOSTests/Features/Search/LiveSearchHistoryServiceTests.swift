import XCTest
@testable import TypeTypeIOS

final class LiveSearchHistoryServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testHistoryAddAndClearUseAuthenticatedServerEndpoints() async throws {
    var requests: [URLRequest] = []
    URLProtocolStub.register { request in
      requests.append(request)
      switch request.httpMethod {
      case "GET":
        return try Self.response(
          request,
          status: 200,
          body: #"[{"id":"one","term":"SABR","searchedAt":12}]"#
        )
      case "POST":
        let body = try XCTUnwrap(URLProtocolStub.bodyData(from: request))
        XCTAssertEqual(
          try JSONDecoder().decode(TermPayload.self, from: body).term,
          "Big Buck Bunny"
        )
        return try Self.response(
          request,
          status: 201,
          body: """
          {"id":"two","term":"Big Buck Bunny","searchedAt":13}
          """
        )
      default:
        return try Self.response(request, status: 204, body: "")
      }
    }
    let service = makeService()

    let history = try await service.history(page: 2, limit: 8)
    let added = try await service.add(term: "Big Buck Bunny")
    try await service.clear()

    XCTAssertEqual(history.first?.term, "SABR")
    XCTAssertEqual(added.id, "two")
    XCTAssertEqual(requests.map(\.httpMethod), ["GET", "POST", "DELETE"])
    XCTAssertTrue(
      requests.allSatisfy {
        $0.value(forHTTPHeaderField: "Authorization") == "Bearer token"
      }
    )
    XCTAssertEqual(
      URLComponents(
        url: try XCTUnwrap(requests.first?.url),
        resolvingAgainstBaseURL: false
      )?.queryItems,
      [
        URLQueryItem(name: "page", value: "2"),
        URLQueryItem(name: "limit", value: "8"),
      ]
    )
  }

  private func makeService() -> LiveSearchHistoryService {
    LiveSearchHistoryService(
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
        headerFields: nil
      )
    )
    return (response, Data(body.utf8))
  }
}

private struct TermPayload: Decodable {
  let term: String
}
