import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveAccountProfileServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testListDecodesProfileContract() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/profiles")
      XCTAssertEqual(request.httpMethod, "GET")
      return try Self.response(request, status: 200, body: Self.profilesJSON)
    }

    let result = try await makeService().list()

    XCTAssertEqual(
      result.activeProfileID,
      "11111111-1111-1111-1111-111111111111"
    )
    XCTAssertEqual(
      result.defaultProfileID,
      "22222222-2222-2222-2222-222222222222"
    )
    XCTAssertEqual(result.profiles.count, 2)
    XCTAssertEqual(result.profiles.first?.name, "Personal")
    XCTAssertEqual(result.profiles.first?.isActive, true)
    XCTAssertEqual(
      result.profiles.last?.avatarURL,
      URL(string: "https://example.test/avatar.png")
    )
  }

  func testCreateSendsNameAndDecodesProfile() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/profiles")
      XCTAssertEqual(request.httpMethod, "POST")
      let body = try XCTUnwrap(URLProtocolStub.bodyData(from: request))
      let payload = try XCTUnwrap(
        JSONSerialization.jsonObject(with: body) as? [String: String]
      )
      XCTAssertEqual(payload["name"], "Kids")
      return try Self.response(
        request,
        status: 201,
        body: Self.kidsProfileJSON
      )
    }

    let profile = try await makeService().create(name: "Kids")

    XCTAssertEqual(profile.id, "22222222-2222-2222-2222-222222222222")
    XCTAssertEqual(profile.name, "Kids")
    XCTAssertFalse(profile.isActive)
    XCTAssertTrue(profile.isDefault)
  }

  func testSwitchTargetsProfileEndpointAndDecodesToken() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(
        request.url?.path,
        "/api/profiles/22222222-2222-2222-2222-222222222222/switch"
      )
      XCTAssertEqual(request.httpMethod, "POST")
      return try Self.response(
        request,
        status: 200,
        body: """
        {
          "accessToken": "profile-token",
          "profile": \(Self.kidsProfileJSON)
        }
        """
      )
    }

    let result = try await makeService().switchTo(
      id: "22222222-2222-2222-2222-222222222222"
    )

    XCTAssertEqual(result.accessToken, "profile-token")
    XCTAssertEqual(result.profile.name, "Kids")
  }

  private func makeService() -> LiveAccountProfileService {
    LiveAccountProfileService(
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
      throw ProfileTestError.missingURL
    }
    guard let response = HTTPURLResponse(
      url: url,
      statusCode: status,
      httpVersion: nil,
      headerFields: ["Content-Type": "application/json"]
    ) else {
      throw ProfileTestError.invalidResponse
    }
    return (response, Data(body.utf8))
  }

  private static let profilesJSON = """
    {
      "profiles": [
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "name": "Personal",
          "isActive": true,
          "isDefault": false,
          "lastUsedAt": 100,
          "publicUsername": "person",
          "avatarUrl": null,
          "avatarType": "emoji",
          "avatarCode": "1F4FA"
        },
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "name": "Kids",
          "isActive": false,
          "isDefault": true,
          "lastUsedAt": 80,
          "publicUsername": null,
          "avatarUrl": "https://example.test/avatar.png",
          "avatarType": "custom",
          "avatarCode": null
        }
      ],
      "activeProfileId": "11111111-1111-1111-1111-111111111111",
      "defaultProfileId": "22222222-2222-2222-2222-222222222222"
    }
    """

  private static let kidsProfileJSON = """
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "name": "Kids",
      "isActive": false,
      "isDefault": true,
      "lastUsedAt": 80,
      "publicUsername": null,
      "avatarUrl": null,
      "avatarType": null,
      "avatarCode": null
    }
    """
}

private enum ProfileTestError: Error {
  case missingURL
  case invalidResponse
}
