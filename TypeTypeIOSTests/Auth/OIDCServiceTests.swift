import Foundation
import XCTest
@testable import TypeTypeIOS

final class OIDCServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testStartAndCompleteUseNativeRedirectURI() async throws {
    URLProtocolStub.register { request in
      switch request.url?.path {
      case "/api/auth/oidc/start":
        let components = try XCTUnwrap(
          URLComponents(
            url: try XCTUnwrap(request.url),
            resolvingAgainstBaseURL: false
          )
        )
        let query = Dictionary(
          uniqueKeysWithValues: (components.queryItems ?? []).map {
            ($0.name, $0.value)
          }
        )
        XCTAssertEqual(
          query["redirectUri"] ?? nil,
          "typetype://auth/oidc/callback"
        )
        XCTAssertEqual(query["returnTo"] ?? nil, "/profile")
        return try Self.response(
          request,
          body: #"{"authorizationUrl":"https://id.test/authorize"}"#
        )
      case "/api/auth/oidc/callback":
        let body = try XCTUnwrap(
          URLProtocolStub.bodyData(from: request)
        )
        let payload = try JSONSerialization.jsonObject(with: body)
          as? [String: String]
        XCTAssertEqual(payload?["code"], "code-1")
        XCTAssertEqual(payload?["state"], "state-1")
        XCTAssertEqual(
          payload?["redirectUri"],
          "typetype://auth/oidc/callback"
        )
        return try Self.response(
          request,
          body: #"{"accessToken":"oidc-token","returnTo":"/profile"}"#
        )
      default:
        throw OIDCTestError.unexpectedPath
      }
    }

    let service = OIDCService(apiClient: makeClient())
    let redirectURI = try XCTUnwrap(
      URL(string: "typetype://auth/oidc/callback")
    )
    let authorizationURL = try await service.start(
      redirectURI: redirectURI,
      returnTo: "/profile"
    )
    XCTAssertEqual(
      authorizationURL.absoluteString,
      "https://id.test/authorize"
    )

    let callback = try await service.complete(
      authorizationCode: OIDCAuthorizationCode(
        code: "code-1",
        state: "state-1"
      ),
      redirectURI: redirectURI
    )
    XCTAssertEqual(callback.accessToken, "oidc-token")
    XCTAssertEqual(callback.returnTo, "/profile")
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
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw OIDCTestError.missingURL
    }
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    ) else {
      throw OIDCTestError.invalidResponse
    }
    return (response, Data(body.utf8))
  }
}

private enum OIDCTestError: Error {
  case missingURL
  case invalidResponse
  case unexpectedPath
}
