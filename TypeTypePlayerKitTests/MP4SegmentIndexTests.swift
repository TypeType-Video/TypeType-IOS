import XCTest
@testable import TypeTypePlayerKit

final class MP4SegmentIndexTests: XCTestCase {
  func testReadsSubsegmentRangesAndTimes() throws {
    typealias B = MP4TestBoxes
    var payload = B.u32(1) + B.u32(1_000) + B.u32(500) + B.u32(100) + B.u16(0) + B.u16(2)
    payload += B.u32(4_000) + B.u32(2_000) + B.u32(0x9000_0000)
    payload += B.u32(3_000) + B.u32(1_500) + B.u32(0x9000_0000)
    let sidx = B.fullBox("sidx", payload)
    let entries = try MP4SegmentIndex.entries(in: Data(sidx), fileOffset: 800)
    let anchor = Int64(800 + sidx.count + 100)
    XCTAssertEqual(entries.map(\.byteRange), [anchor..<(anchor + 4_000), (anchor + 4_000)..<(anchor + 7_000)])
    XCTAssertEqual(entries.map(\.startTime), [0.5, 2.5])
    XCTAssertEqual(entries.map(\.duration), [2.0, 1.5])
  }
}
