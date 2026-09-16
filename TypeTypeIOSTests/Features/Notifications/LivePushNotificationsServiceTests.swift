import Foundation
import XCTest
@testable import TypeTypeIOS

final class LivePushNotificationsServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testChannelPreferencesUseAuthenticatedContract() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(
        request.url?.path,
        "/api/notifications/channel-preferences"
      )
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer test-token"
      )
      return try Self.response(
        request,
        status: 200,
        body: """
        [
          {
            "channelUrl": "https://youtube.test/channel/one",
            "enabled": true,
            "updatedAt": 20
          }
        ]
        """
      )
    }

    let preferences = try await makeService().channelPreferences()

    XCTAssertEqual(preferences.count, 1)
    XCTAssertTrue(
      preferences[0].matches(
        channelURL: "https://youtube.test/channel/one/"
      )
    )
  }

  func testUpdateChannelPreferenceSendsEnabledState() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(
        request.url?.path,
        "/api/notifications/channel-preferences"
      )
      XCTAssertEqual(request.httpMethod, "PUT")
      let body = try XCTUnwrap(URLProtocolStub.bodyData(from: request))
      let payload = try XCTUnwrap(
        JSONSerialization.jsonObject(with: body) as? [String: Bool]
      )
      XCTAssertEqual(payload["enabled"], true)
      return try Self.response(
        request,
        status: 200,
        body: """
        {
          "channelUrl": "https://youtube.test/channel/one",
          "enabled": true,
          "updatedAt": 30
        }
        """
      )
    }

    let preference = try await makeService().setChannelPreference(
      channelURL: "https://youtube.test/channel/one",
      enabled: true
    )

    XCTAssertTrue(preference.enabled)
    XCTAssertEqual(preference.updatedAt, 30)
  }

  private func makeService() -> LivePushNotificationsService {
    LivePushNotificationsService(
      apiClient: URLSessionAPIClient(
        serverURLProvider: {
          URL(string: "https://example.test/api")
        },
        accessTokenProvider: { "test-token" },
        session: Self.makeSession()
      )
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
      throw PushTestError.missingURL
    }
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: status,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    ) else {
      throw PushTestError.invalidResponse
    }
    return (response, Data(body.utf8))
  }
}

private enum PushTestError: Error {
  case missingURL
  case invalidResponse
}
