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

  func testRetriesTransientReadFailureWithoutDuplicatingMutations()
    async throws
  {
    let state = RequestCounter()
    URLProtocolStub.register { request in
      let attempt = state.increment()
      if attempt == 1 {
        throw URLError(.networkConnectionLost)
      }
      return try Self.response(
        request: request,
        status: 200,
        body: #"{"value":"recovered"}"#
      )
    }
    let client = makeClient(token: { nil })

    let response = try await client.request(
      APIEndpoint(path: "/recommendations", method: .get),
      as: TestResponse.self
    )

    XCTAssertEqual(response.value, "recovered")
    XCTAssertEqual(state.value, 2)

    URLProtocolStub.register { _ in
      _ = state.increment()
      throw URLError(.networkConnectionLost)
    }
    do {
      try await client.request(
        APIEndpoint(path: "/history", method: .post)
      )
      XCTFail("The mutation should fail without being retried.")
    } catch {
      XCTAssertEqual(state.value, 3)
    }
  }

  func testRefusalsMarkedFinalAreNotRetried() async {
    let state = RequestCounter()
    URLProtocolStub.register { request in
      _ = state.increment()
      return try Self.response(request: request, status: 503, body: #"{"error":"no bootstrap"}"#)
    }
    let client = makeClient(token: { nil })

    do {
      try await client.request(
        APIEndpoint(path: "/streams/youtube/sabr/bootstrap", method: .get, retriesTransientFailures: false)
      )
      XCTFail("A 503 should be reported.")
    } catch {
      XCTAssertEqual(state.value, 1)
    }
  }

  func testStreamsFileUploadAndRetriesWithRefreshedToken() async throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: false
    )
    defer { try? FileManager.default.removeItem(at: directory) }
    let fileURL = directory.appendingPathComponent("upload.multipart")
    let expectedBody = Data("multipart-body".utf8)
    try expectedBody.write(to: fileURL)

    let state = UploadRequestState()
    URLProtocolStub.register { request in
      let authorization = request.value(
        forHTTPHeaderField: "Authorization"
      )
      let body = try URLProtocolStub.bodyData(from: request)
      state.record(authorization: authorization, body: body)
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Content-Type"),
        "multipart/form-data; boundary=test"
      )
      return try Self.response(
        request: request,
        status: authorization == "Bearer refreshed" ? 200 : 401,
        body: authorization == "Bearer refreshed"
          ? #"{"value":"ok"}"#
          : #"{"error":"expired"}"#
      )
    }

    let client = makeClient(token: { "expired" })
    client.setTokenRefreshHandler { token in
      XCTAssertEqual(token, "expired")
      return "refreshed"
    }
    let response = try await client.upload(
      APIEndpoint(
        path: "/imports/youtube-takeout",
        method: .post,
        headers: [
          "Content-Type": "multipart/form-data; boundary=test",
        ],
        requiresAuth: true
      ),
      from: fileURL,
      as: TestResponse.self
    )

    XCTAssertEqual(response.value, "ok")
    XCTAssertEqual(
      state.authorizationHeaders,
      ["Bearer expired", "Bearer refreshed"]
    )
    XCTAssertEqual(state.bodies, [expectedBody, expectedBody])
  }

  func testDownloadsAuthenticatedArtifactAndRetriesWithRefreshedToken()
    async throws
  {
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
          ? "downloaded-media"
          : #"{"error":"expired"}"#
      )
    }

    let client = makeClient(token: state.readToken)
    client.setTokenRefreshHandler { staleToken in
      XCTAssertEqual(staleToken, "expired")
      state.updateToken("refreshed")
      return "refreshed"
    }

    let fileURL = try await client.download(
      APIEndpoint(
        path: "/downloader/jobs/job-1/artifact",
        method: .get,
        requiresAuth: true
      )
    )
    defer { try? FileManager.default.removeItem(at: fileURL) }

    XCTAssertEqual(
      try Data(contentsOf: fileURL),
      Data("downloaded-media".utf8)
    )
    XCTAssertEqual(
      state.authorizationHeaders,
      ["Bearer expired", "Bearer refreshed"]
    )
  }

  func testRecordsSanitizedDiagnosticsWithRequestID() async {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let store = LiveDiagnosticsStore(rootURL: rootURL)
    let scope = LiveDiagnosticScope(
      serverID: "server-1",
      accountID: "account-1"
    )
    URLProtocolStub.register { request in
      guard let url = request.url,
        let response = HTTPURLResponse(
          url: url,
          statusCode: 422,
          httpVersion: nil,
          headerFields: [
            "Content-Type": "application/json",
            "X-Request-Id": "request-test-123",
          ]
        )
      else {
        throw TestError.invalidResponse
      }
      return (response, Data(#"{"error":"invalid"}"#.utf8))
    }
    let client = URLSessionAPIClient(
      serverURLProvider: {
        URL(string: "https://example.test/api")
      },
      accessTokenProvider: { "token" },
      session: Self.makeSession(),
      diagnosticsStore: store,
      diagnosticScopeProvider: { scope }
    )

    do {
      try await client.request(
        APIEndpoint(
          path: "/history/private-video-id",
          method: .delete,
          queryItems: [
            URLQueryItem(name: "secret", value: "never-store-me"),
          ],
          requiresAuth: true
        )
      )
      XCTFail("Expected HTTP 422.")
    } catch {
      // The request failure is the event under test.
    }

    let entries = await store.entries(for: scope)
    XCTAssertEqual(entries.count, 1)
    XCTAssertEqual(entries.first?.method, "DELETE")
    XCTAssertEqual(entries.first?.route, "/history/:id")
    XCTAssertEqual(entries.first?.statusCode, 422)
    XCTAssertEqual(entries.first?.requestID, "request-test-123")
    XCTAssertFalse(entries.first?.route.contains("private-video-id") == true)
    XCTAssertFalse(entries.first?.route.contains("never-store-me") == true)
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

private final class UploadRequestState {
  private let lock = NSLock()
  private var headers: [String] = []
  private var requestBodies: [Data] = []

  var authorizationHeaders: [String] {
    lock.withLock { headers }
  }

  var bodies: [Data] {
    lock.withLock { requestBodies }
  }

  func record(authorization: String?, body: Data?) {
    lock.withLock {
      headers.append(authorization ?? "")
      requestBodies.append(body ?? Data())
    }
  }
}

private final class RequestCounter {
  private let lock = NSLock()
  private var count = 0

  var value: Int {
    lock.withLock { count }
  }

  func increment() -> Int {
    lock.withLock {
      count += 1
      return count
    }
  }
}
