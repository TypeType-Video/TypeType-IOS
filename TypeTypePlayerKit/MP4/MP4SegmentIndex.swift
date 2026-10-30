import Foundation

public struct MP4IndexEntry: Equatable, Sendable {
  public let byteRange: Range<Int64>
  public let startTime: TimeInterval
  public let duration: TimeInterval
}

public enum MP4SegmentIndex {
  public static func entries(in data: Data, fileOffset: Int64) throws -> [MP4IndexEntry] {
    try data.withUnsafeBytes { bytes in
      let reader = MP4ByteReader(bytes: bytes)
      let sidx = try reader.requiredBox(MP4FourCC("sidx"), in: 0..<bytes.count)
      let base = sidx.content.lowerBound
      let version = try reader.uint8(at: base)
      let timescale = Double(try reader.uint32(at: base + 8))
      guard timescale > 0 else { throw MP4Error.invalidBox("sidx") }
      var cursor = base + 12
      let earliest: UInt64
      let firstOffset: UInt64
      if version == 0 {
        earliest = UInt64(try reader.uint32(at: cursor))
        firstOffset = UInt64(try reader.uint32(at: cursor + 4))
        cursor += 8
      } else {
        earliest = try reader.uint64(at: cursor)
        firstOffset = try reader.uint64(at: cursor + 8)
        cursor += 16
      }
      let count = Int(try reader.uint16(at: cursor + 2))
      cursor += 4
      var entries: [MP4IndexEntry] = []
      entries.reserveCapacity(count)
      var start = fileOffset + Int64(sidx.end - sidx.start) + Int64(clamping: firstOffset)
      var time = Double(earliest)
      for _ in 0..<count {
        let reference = try reader.uint32(at: cursor)
        let duration = Double(try reader.uint32(at: cursor + 4))
        cursor += 12
        guard reference & 0x8000_0000 == 0 else { throw MP4Error.invalidBox("nested sidx") }
        let size = Int64(reference & 0x7FFF_FFFF)
        entries.append(
          MP4IndexEntry(
            byteRange: start..<(start + size),
            startTime: time / timescale,
            duration: duration / timescale
          )
        )
        start += size
        time += duration
      }
      return entries
    }
  }
}
