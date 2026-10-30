import XCTest

@testable import TypeTypeIOS

final class LiveCrashReportTests: XCTestCase {
  private let tree = Data(
    """
    {"callStackPerThread":true,"callStacks":[
      {"threadAttributed":false,"callStackRootFrames":[{"binaryName":"libsystem","offsetIntoBinaryTextSegment":1}]},
      {"threadAttributed":true,"callStackRootFrames":[
        {"binaryName":"TypeTypeIOS","offsetIntoBinaryTextSegment":4096,"subFrames":[
          {"binaryName":"SwiftUI","offsetIntoBinaryTextSegment":512}
        ]}
      ]}
    ]}
    """.utf8
  )

  func testFramesFollowTheCrashedThread() {
    XCTAssertEqual(LiveCrashReport.frames(fromCallStackTree: tree), ["TypeTypeIOS +4096", "SwiftUI +512"])
  }

  func testUnreadableStackGivesNoFrames() {
    XCTAssertEqual(LiveCrashReport.frames(fromCallStackTree: Data("nope".utf8)), [])
  }

  func testReportTextHoldsOnlyTechnicalFields() {
    let report = LiveCrashReport(
      kind: .crash,
      date: Date(timeIntervalSince1970: 0),
      appVersion: "0.2.0",
      system: "iPhone OS 26.7",
      device: "iPhone12,8",
      exceptionType: 1,
      signal: 11,
      terminationReason: "Namespace SIGNAL, Code 11",
      hangSeconds: nil,
      frames: ["TypeTypeIOS +4096"]
    )

    XCTAssertTrue(report.text.contains("Signal: 11"))
    XCTAssertTrue(report.text.contains("  TypeTypeIOS +4096"))
    XCTAssertFalse(report.text.contains("Hang"))
  }

  func testArchiveKeepsTheNewestTenAndClears() async throws {
    let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }
    let archive = LiveCrashReportArchive(fileURL: url)
    let reports = (0..<12).map { index in
      LiveCrashReport(
        kind: .hang, date: Date(timeIntervalSince1970: Double(index)), appVersion: "1", system: "iOS",
        device: "iPhone", exceptionType: nil, signal: nil, terminationReason: nil, hangSeconds: 2, frames: []
      )
    }

    await archive.append(reports)
    let kept = await archive.reports()
    XCTAssertEqual(kept.count, 10)
    XCTAssertEqual(kept.first?.date, Date(timeIntervalSince1970: 11))

    await archive.clear()
    let cleared = await archive.reports()
    XCTAssertTrue(cleared.isEmpty)
  }
}
