import Foundation
import XCTest
@testable import TypeTypeIOS

final class ResetPasswordServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testResetSendsCurrentServerPayload() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/auth/reset-password")
      XCTAssertEqual(request.httpMethod, "POST")
      let body = try XCTUnwrap(
        URLProtocolStub.bodyData(from: request)
      )
      let payload = try JSONSerialization.jsonObject(with: body)
        as? [String: String]
      XCTAssertEqual(payload?["resetToken"], "reset-1")
      XCTAssertEqual(payload?["newPassword"], "new-secret")
      return try Self.response(for: request)
    }

    let service = ResetPasswordService(apiClient: makeClient())
    try await service.reset(
      token: "reset-1",
      newPassword: "new-secret"
    )
  }

  private func makeClient() -> URLSessionAPIClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSessionAPIClient(
      serverURLProvider: {
        URL(string: "https://example.test/api")
      },
      accessTokenProvider: { nil },
      session: URLSession(configuration: configuration)
    )
  }

  private static func response(
    for request: URLRequest
  ) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url,
      let response = HTTPURLResponse(
        url: url,
        statusCode: 204,
        httpVersion: nil,
        headerFields: nil
      )
    else {
      throw ResetTestError.invalidResponse
    }
    return (response, Data())
  }
}

private enum ResetTestError: Error {
  case invalidResponse
}
