import Foundation
import XCTest
@testable import TypeTypeIOS

final class MultipartFormFileTests: XCTestCase {
  func testBuildsMultipartEnvelopeAroundSourceFile() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: false
    )
    defer { try? FileManager.default.removeItem(at: directory) }
    let sourceURL = directory.appendingPathComponent("takeout.zip")
    try Data("archive-payload".utf8).write(to: sourceURL)

    let form = try MultipartFormFile(
      sourceURL: sourceURL,
      fieldName: "archive",
      fileName: "takeout.zip",
      mediaType: "application/zip"
    )
    defer { try? FileManager.default.removeItem(at: form.fileURL) }
    let body = try String(
      decoding: Data(contentsOf: form.fileURL),
      as: UTF8.self
    )
    let boundary = try XCTUnwrap(
      form.contentType.components(separatedBy: "boundary=").last
    )

    XCTAssertTrue(body.hasPrefix("--\(boundary)\r\n"))
    XCTAssertTrue(
      body.contains(
        #"name="archive"; filename="takeout.zip""#
      )
    )
    XCTAssertTrue(
      body.contains("Content-Type: application/zip\r\n\r\n")
    )
    XCTAssertTrue(body.contains("archive-payload"))
    XCTAssertTrue(body.hasSuffix("\r\n--\(boundary)--\r\n"))
  }
}
