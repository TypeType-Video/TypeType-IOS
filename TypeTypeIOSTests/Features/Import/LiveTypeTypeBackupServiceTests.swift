import Foundation
import XCTest
@testable import TypeTypeIOS

final class LiveTypeTypeBackupServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testExportSendsSelectedCategoriesAndDownloadsBackup() async throws {
    let expectedBackup = Data(#"{"format":"typetype-backup","version":1}"#.utf8)
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/backup/typetype")
      XCTAssertEqual(
        request.url?.query,
        "categories=contentFilters,subscriptions,watchLater"
      )
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer test-token"
      )
      return try Self.response(
        request,
        status: 200,
        body: expectedBackup
      )
    }
    let service = Self.makeService()

    let url = try await service.exportTypeTypeBackup(
      categories: [
        .subscriptions,
        .watchLater,
        .contentFilters,
      ]
    )
    defer { try? FileManager.default.removeItem(at: url) }

    XCTAssertEqual(try Data(contentsOf: url), expectedBackup)
  }

  func testRestoreUploadsSingleJSONFileAndDecodesCounts() async throws {
    URLProtocolStub.register { request in
      XCTAssertEqual(request.url?.path, "/api/restore/typetype")
      XCTAssertEqual(request.httpMethod, "POST")
      XCTAssertEqual(
        request.value(forHTTPHeaderField: "Authorization"),
        "Bearer test-token"
      )
      let contentType = try XCTUnwrap(
        request.value(forHTTPHeaderField: "Content-Type")
      )
      XCTAssertTrue(contentType.hasPrefix("multipart/form-data"))
      let body = String(
        decoding: try URLProtocolStub.bodyData(from: request) ?? Data(),
        as: UTF8.self
      )
      XCTAssertTrue(body.contains("typetype-backup.json"))
      XCTAssertTrue(body.contains(#""format":"typetype-backup""#))
      XCTAssertTrue(body.contains(#""version":1"#))
      return try Self.response(
        request,
        status: 200,
        body: Data(
          #"{"restored":{"subscriptions":2,"history":5}}"#.utf8
        )
      )
    }
    let service = Self.makeService()

    let summary = try await service.restoreTypeTypeBackup(
      data: Data(#"{"format":"typetype-backup","version":1}"#.utf8),
      fileName: "typetype-backup.json",
      categories: [
        .subscriptions,
        .history,
        .playlists,
        .watchLater,
        .favorites,
        .progress,
        .searchHistory,
        .savedPlaylists,
        .settings,
        .contentFilters,
      ]
    )

    XCTAssertEqual(summary.restored["subscriptions"], 2)
    XCTAssertEqual(summary.restored["history"], 5)
    XCTAssertEqual(summary.total, 7)
  }

  func testRestoreFiltersSelectedCategories() throws {
    let source = Data(
      """
      {
        "format":"typetype-backup",
        "version":1,
        "exportedAt":1,
        "categories":["history","subscriptions","settings"],
        "subscriptions":[],
        "history":[],
        "settings":{}
      }
      """.utf8
    )

    let filtered = try LiveImportService.filterTypeTypeBackup(
      data: source,
      categories: [.history, .settings]
    )
    let object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: filtered) as? [String: Any]
    )

    XCTAssertEqual(object["categories"] as? [String], [
      "history",
      "settings",
    ])
    XCTAssertNotNil(object["history"])
    XCTAssertNotNil(object["settings"])
    XCTAssertNil(object["subscriptions"])
  }

  func testRestoreKeepsSelectedCategoriesWhenMetadataIsMissing() throws {
    // Backups without a "categories" metadata list used to be stripped to
    // nothing: the empty intersection dropped every selected category and
    // the server restored zero entries without reporting an error.
    let source = Data(
      """
      {
        "format":"typetype-backup",
        "version":1,
        "subscriptions":[],
        "history":[],
        "settings":{}
      }
      """.utf8
    )

    let filtered = try LiveImportService.filterTypeTypeBackup(
      data: source,
      categories: [.subscriptions, .history, .settings]
    )
    let object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: filtered) as? [String: Any]
    )

    XCTAssertEqual(
      object["categories"] as? [String],
      ["history", "settings", "subscriptions"]
    )
    XCTAssertNotNil(object["subscriptions"])
    XCTAssertNotNil(object["history"])
    XCTAssertNotNil(object["settings"])
  }

  func testRestoreWithoutMetadataKeepsOnlySelectedCategories() throws {
    let source = Data(
      """
      {
        "format":"typetype-backup",
        "version":1,
        "subscriptions":[],
        "history":[],
        "settings":{}
      }
      """.utf8
    )

    let filtered = try LiveImportService.filterTypeTypeBackup(
      data: source,
      categories: [.history]
    )
    let object = try XCTUnwrap(
      JSONSerialization.jsonObject(with: filtered) as? [String: Any]
    )

    XCTAssertEqual(object["categories"] as? [String], ["history"])
    XCTAssertNotNil(object["history"])
    XCTAssertNil(object["subscriptions"])
    XCTAssertNil(object["settings"])
  }

  private static func makeService() -> LiveImportService {
    LiveImportService(
      apiClient: URLSessionAPIClient(
        serverURLProvider: { URL(string: "https://example.test/api") },
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
    body: Data
  ) throws -> (HTTPURLResponse, Data) {
    guard let url = request.url else {
      throw TestError.missingURL
    }
    let response = try XCTUnwrap(
      HTTPURLResponse(
        url: url,
        statusCode: status,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
      )
    )
    return (response, body)
  }
}

private enum TestError: Error {
  case missingURL
}
