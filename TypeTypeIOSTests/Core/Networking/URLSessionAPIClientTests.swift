import Foundation
import XCTest
@testable import TypeTypeIOS

final class URLSessionAPIClientTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testDefaultSessionAcceptsAndPersistsRefreshCookies() {
    let session = URLSessionAPIClient.makeSession()
    let configuration = session.configuration

    XCTAssertTrue(configuration.httpShouldSetCookies)
    XCTAssertEqual(configuration.httpCookieAcceptPolicy, .always)
    XCTAssertTrue(
      configuration.httpCookieStorage === HTTPCookieStorage.shared
    )
  }

  func testBuildsRequestFromServerAPIBase() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/search")
      XCTAssertEqual(request.url?.query, "q=swift&service=0")
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer access-token"
      )
      return try Self.response(
        request: request,
        status: 200,
        body: #"{"value":"ok"}"#
      )
    }

    let client = makeClient(token: { "access-token" })
    let endpoint = APIEndpoint(
      path: "/search",
      method: .get,
      queryItems: [
        URLQueryItem(name: "q", value: "swift"),
        URLQueryItem(name: "service", value: "0"),
      ],
      requiresAuth: true
    )

    let response = try await client.request(
      endpoint,
      as: TestResponse.self
    )
    XCTAssertEqual(response.value, "ok")
  }

  func testRetriesOnceWithRefreshedAccessToken() async throws {
    let state = RequestState(token: "expired")
    URLProtocolStub.register { request in
      let authorization = request.value(
        forHTTPHeaderField: "Authorization"
      )
      state.record(authorization)
      return try Self.response(
        request: request,
        status: authorization == "Bearer refreshed" ? 200 : 401,
        body: authorization == "Bearer refreshed"
          ? #"{"value":"ok"}"#
          : #"{"error":"expired"}"#
      )
    }

    let client = makeClient(token: state.readToken)
    client.setTokenRefreshHandler { staleToken in
      XCTAssertEqual(staleToken, "expired")
      state.updateToken("refreshed")
      return "refreshed"
    }

    let response = try await client.request(
      APIEndpoint(
        path: "/history",
        method: .get,
        requiresAuth: true
      ),
      as: TestResponse.self
    )

    XCTAssertEqual(response.value, "ok")
    XCTAssertEqual(
      state.authorizationHeaders,
      ["Bearer expired", "Bearer refreshed"]
    )
  }

  func testDoesNotRefreshPublicUnauthorizedRequest() async {
    let state = RequestState(token: "expired")
    URLProtocolStub.register { request in
      try Self.response(
        request: request,
        status: 401,
        body: #"{"error":"denied"}"#
      )
    }
    let client = makeClient(token: state.readToken)
    client.setTokenRefreshHandler { _ in
      XCTFail("Public requests must not refresh a session.")
      return nil
    }

    do {
      try await client.request(
        APIEndpoint(path: "/instance", method: .get)
      )
      XCTFail("Expected HTTP 401.")
    } catch let error as NetworkError {
      guard case let .statusCode(status, message) = error else {
        return XCTFail("Expected a status-code error.")
      }
      XCTAssertEqual(status, 401)
      XCTAssertEqual(message, "denied")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  private func makeClient(
    token: @escaping () -> String?
  ) -> URLSessionAPIClient {
    URLSessionAPIClient(
      serverURLProvider: {
        URL(string: "https://example.test/api")
      },
      accessTokenProvider: token,
      session: Self.makeSession()
    )
  }

  private static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    request: URLRequest,
    status: Int,
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw TestError.missingURL
    }
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: status,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    ) else {
      throw TestError.invalidResponse
    }
    return (response, Data(body.utf8))
  }
}

private struct TestResponse: Decodable {
  let value: String
}

private enum TestError: Error {
  case missingURL
  case invalidResponse
}

private final class RequestState {
  private let lock = NSLock()
  private var token: String
  private var headers: [String] = []

  init(token: String) {
    self.token = token
  }

  var authorizationHeaders: [String] {
    lock.withLock { headers }
  }

  func readToken() -> String {
    lock.withLock { token }
  }

  func updateToken(_ token: String) {
    lock.withLock {
      self.token = token
    }
  }

  func record(_ header: String?) {
    lock.withLock {
      headers.append(header ?? "")
    }
  }
}
