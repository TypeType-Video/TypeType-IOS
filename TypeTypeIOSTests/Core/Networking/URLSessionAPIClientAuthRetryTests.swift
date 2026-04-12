import Foundation
import XCTest
@testable import TypeTypeIOS

final class URLSessionAPIClientAuthRetryTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testRetriesAuthenticatedRequestAfterUnauthorized() async throws {
    let metrics = RequestMetrics()
    let tokenBox = LockedToken("expired-token")

    URLProtocolStub.register { request in
      guard let url = request.url else { throw TestError.invalidRequest }
      switch url.path {
      case "/api/history":
        let auth = request.value(forHTTPHeaderField: "Authorization") ?? ""
        metrics.recordHistoryAuth(auth)
        if auth == "Bearer expired-token" {
          return Self.response(url: url, status: 401, body: "{\"error\":\"expired\"}")
        }
        if auth == "Bearer new-token" {
          return Self.response(url: url, status: 200, body: "[]")
        }
        return Self.response(url: url, status: 401, body: "{\"error\":\"invalid\"}")
      case "/api/auth/refresh":
        metrics.incrementRefreshCalls()
        return Self.response(url: url, status: 200, body: "{\"token\":\"new-token\"}")
      default:
        return Self.response(url: url, status: 404, body: "{\"error\":\"not-found\"}")
      }
    }

    let client = URLSessionAPIClient(
      serverURLProvider: { URL(string: "https://example.com/api") },
      accessTokenProvider: { tokenBox.read() },
      session: Self.makeSession()
    )
    let authService = AuthService(apiClient: client)
    client.setTokenRefreshHandler { staleToken in
      let refreshedToken = try await authService.refresh(using: staleToken)
      tokenBox.write(refreshedToken)
      return refreshedToken
    }

    let endpoint = APIEndpoint(path: "/history", method: .get, requiresAuth: true)
    let payload = try await client.request(endpoint, as: [String].self)

    XCTAssertTrue(payload.isEmpty)
    XCTAssertEqual(metrics.refreshCalls, 1)
    XCTAssertEqual(metrics.historyAuthHeaders, ["Bearer expired-token", "Bearer new-token"])
  }

  func testDoesNotRefreshForNonAuthenticatedEndpoint() async {
    let metrics = RequestMetrics()
    let tokenBox = LockedToken("expired-token")

    URLProtocolStub.register { request in
      guard let url = request.url else { throw TestError.invalidRequest }
      if url.path == "/api/trending" {
        return Self.response(url: url, status: 401, body: "{\"error\":\"unauthorized\"}")
      }
      return Self.response(url: url, status: 404, body: "{\"error\":\"not-found\"}")
    }

    let client = URLSessionAPIClient(
      serverURLProvider: { URL(string: "https://example.com/api") },
      accessTokenProvider: { tokenBox.read() },
      session: Self.makeSession()
    )
    client.setTokenRefreshHandler { _ in
      metrics.incrementRefreshCalls()
      return "new-token"
    }

    do {
      try await client.request(APIEndpoint(path: "/trending", method: .get))
      XCTFail("Expected unauthorized response")
    } catch let error as NetworkError {
      guard case .statusCode(401, _) = error else {
        return XCTFail("Expected status 401")
      }
    } catch {
      XCTFail("Expected NetworkError, got \(error)")
    }

    XCTAssertEqual(metrics.refreshCalls, 0)
  }

  private static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(url: URL, status: Int, body: String) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(
      url: url,
      statusCode: status,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    )!
    return (response, Data(body.utf8))
  }
}

private enum TestError: Error {
  case invalidRequest
}

private final class LockedToken {
  private let lock = NSLock()
  private var token: String

  init(_ token: String) {
    self.token = token
  }

  func read() -> String {
    lock.lock()
    defer { lock.unlock() }
    return token
  }

  func write(_ token: String) {
    lock.lock()
    self.token = token
    lock.unlock()
  }
}

private final class RequestMetrics {
  private let lock = NSLock()
  private var values: [String] = []
  private var refreshCount: Int = 0

  var historyAuthHeaders: [String] {
    lock.lock()
    defer { lock.unlock() }
    return values
  }

  var refreshCalls: Int {
    lock.lock()
    defer { lock.unlock() }
    return refreshCount
  }

  func recordHistoryAuth(_ value: String) {
    lock.lock()
    values.append(value)
    lock.unlock()
  }

  func incrementRefreshCalls() {
    lock.lock()
    refreshCount += 1
    lock.unlock()
  }
}
