import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveBugReportsServiceTests: XCTestCase {
  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testReportAttachesRecentSanitizedAPIErrors() async throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let store = LiveDiagnosticsStore(rootURL: rootURL)
    let scope = LiveDiagnosticScope(
      serverID: "server-1",
      accountID: "account-1"
    )
    await store.record(
      scope: scope,
      method: "GET",
      requestURL: try XCTUnwrap(
        URL(
          string:
            "https://example.test/api/streams/youtube/sabr?url=private"
        )
      ),
      baseURL: try XCTUnwrap(
        URL(string: "https://example.test/api")
      ),
      statusCode: 422,
      durationMilliseconds: 34,
      requestID: "request-sabr-123"
    )

    var requestBody = Data()
    URLProtocolStub.register { request in
      requestBody = try XCTUnwrap(
        URLProtocolStub.bodyData(from: request)
      )
      return try Self.response(
        request,
        body:
          #"{"id":"report-1","status":"open","createdAt":1785175000000}"#
      )
    }
    let client = URLSessionAPIClient(
      serverURLProvider: {
        URL(string: "https://example.test/api")
      },
      accessTokenProvider: { "token" },
      session: Self.session()
    )
    let service = LiveBugReportsService(
      apiClient: client,
      diagnosticsStore: store,
      diagnosticScopeProvider: { scope }
    )

    _ = try await service.create(
      category: "player",
      description: "Playback failed after opening the video.",
      videoURL: nil
    )

    let json = try XCTUnwrap(
      JSONSerialization.jsonObject(with: requestBody)
        as? [String: Any]
    )
    let context = try XCTUnwrap(json["context"] as? [String: Any])
    let errors = try XCTUnwrap(
      context["apiErrors"] as? [[String: Any]]
    )
    XCTAssertEqual(errors.count, 1)
    XCTAssertEqual(
      errors.first?["endpoint"] as? String,
      "/streams/youtube/sabr"
    )
    XCTAssertEqual(errors.first?["status"] as? Int, 422)
    XCTAssertEqual(
      errors.first?["requestId"] as? String,
      "request-sabr-123"
    )
    XCTAssertFalse(
      String(data: requestBody, encoding: .utf8)?
        .contains("url=private") == true
    )
  }

  private static func session() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
  }

  private static func response(
    _ request: URLRequest,
    body: String
  ) throws -> (HTTPURLResponse, Data) {
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: try XCTUnwrap(request.url),
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, Data(body.utf8))
  }
}
