import Foundation
import XCTest
@testable import TypeTypeIOS

final class AuthServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testLoginUsesCurrentAccessTokenContract() async throws {
    URLProtocolStub.register { request in
      switch request.url?.path {
      case "/api/auth/login":
        let body = try XCTUnwrap(
          URLProtocolStub.bodyData(from: request)
        )
        let payload = try JSONSerialization.jsonObject(with: body)
          as? [String: String]
        XCTAssertEqual(payload?["identifier"], "person@example.test")
        XCTAssertEqual(payload?["password"], "secret")
        return try Self.response(
          request,
          status: 200,
          body: #"{"accessToken":"live-token"}"#
        )
      case "/api/auth/me":
        XCTAssertEqual(
          request.value(forHTTPHeaderField: "Authorization"),
          "Bearer live-token"
        )
        return try Self.response(
          request,
          status: 200,
          body: Self.userJSON
        )
      default:
        throw AuthTestError.unexpectedPath
      }
    }

    let result = try await makeService().login(
      identifier: "person@example.test",
      password: "secret"
    )

    XCTAssertEqual(result.accessToken, "live-token")
    XCTAssertEqual(result.user.id, "user-1")
    XCTAssertEqual(result.user.role, .admin)
    XCTAssertEqual(
      result.accountIdentifier,
      "person@example.test"
    )
  }

  func testGuestSupportsLegacyTokenResponseField() async throws {
    URLProtocolStub.register { request in
      switch request.url?.path {
      case "/api/auth/guest":
        return try Self.response(
          request,
          status: 200,
          body: #"{"token":"guest-token"}"#
        )
      case "/api/auth/me":
        return try Self.response(
          request,
          status: 200,
          body: Self.userJSON
        )
      default:
        throw AuthTestError.unexpectedPath
      }
    }

    let result = try await makeService().guestLogin()
    XCTAssertEqual(result.accessToken, "guest-token")
    XCTAssertNil(result.accountIdentifier)
  }

  func testRefreshUsesCookieCompatibleEmptyPayload() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/auth/refresh")
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(
        try URLProtocolStub.bodyData(from: request),
        Data("{}".utf8)
      )
      return try Self.response(
        request,
        status: 200,
        body: #"{"accessToken":"refreshed"}"#
      )
    }

    let token = try await makeService().refresh()
    XCTAssertEqual(token, "refreshed")
  }

  func testRegisterUsesCurrentPayloadAndReturnsSession() async throws {
    URLProtocolStub.register { request in
      switch request.url?.path {
      case "/api/auth/register":
        let body = try XCTUnwrap(
          URLProtocolStub.bodyData(from: request)
        )
        let payload = try JSONSerialization.jsonObject(with: body)
          as? [String: String]
        XCTAssertEqual(payload?["name"], "Person")
        XCTAssertEqual(payload?["email"], "person@example.test")
        XCTAssertEqual(payload?["password"], "secret-value")
        return try Self.response(
          request,
          status: 200,
          body: #"{"accessToken":"registered-token"}"#
        )
      case "/api/auth/me":
        return try Self.response(
          request,
          status: 200,
          body: Self.userJSON
        )
      default:
        throw AuthTestError.unexpectedPath
      }
    }

    let result = try await makeService().register(
      name: "Person",
      email: "person@example.test",
      password: "secret-value"
    )

    XCTAssertEqual(result.accessToken, "registered-token")
    XCTAssertEqual(
      result.accountIdentifier,
      "person@example.test"
    )
  }

  func testLogoutUsesServerCookieEndpoint() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/auth/logout")
      XCTAssertEqual(request.httpMethod, "POST")
      return try Self.response(
        request,
        status: 204,
        body: ""
      )
    }

    try await makeService().logout()
  }

  private func makeService() -> AuthService {
    AuthService(apiClient: makeClient())
  }

  private func makeClient() -> URLSessionAPIClient {
    URLSessionAPIClient(
      serverURLProvider: {
        URL(string: "https://example.test/api")
      },
      accessTokenProvider: { nil },
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
      throw AuthTestError.missingURL
    }
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: status,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    ) else {
      throw AuthTestError.invalidResponse
    }
    return (response, Data(body.utf8))
  }

  private static let userJSON = """
    {
      "id": "user-1",
      "role": "admin",
      "publicUsername": "priveetee",
      "bio": null,
      "avatarUrl": null,
      "avatarType": "emoji",
      "avatarCode": "1F4FA"
    }
    """
}

private enum AuthTestError: Error {
  case missingURL
  case invalidResponse
  case unexpectedPath
}
