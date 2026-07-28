import Foundation

struct LiveProviderSegmentReference: Equatable {
  let byteCount: Int
  let duration: TimeInterval
}

struct LiveProviderSegmentIndex: Equatable {
  let firstOffset: Int64
  let references: [LiveProviderSegmentReference]

  static func parse(_ data: Data) throws -> Self {
    guard data.count >= 32,
      String(data: data[4..<8], encoding: .ascii) == "sidx",
      let version = data.byte(at: 8),
      let timescale = data.uint32(at: 16),
      timescale > 0
    else {
      throw LivePlaybackFailure.invalidPlaylist
    }

    let firstOffsetPosition: Int
    let referenceCountPosition: Int
    switch version {
    case 0:
      firstOffsetPosition = 24
      referenceCountPosition = 30
    case 1:
      firstOffsetPosition = 28
      referenceCountPosition = 38
    default:
      throw LivePlaybackFailure.invalidPlaylist
    }

    let firstOffset: UInt64?
    if version == 0 {
      firstOffset = data.uint32(at: firstOffsetPosition).map(UInt64.init)
    } else {
      firstOffset = data.uint64(at: firstOffsetPosition)
    }
    guard let firstOffset,
      let referenceCount = data.uint16(at: referenceCountPosition)
    else {
      throw LivePlaybackFailure.invalidPlaylist
    }

    var references: [LiveProviderSegmentReference] = []
    var cursor = referenceCountPosition + 2
    for _ in 0..<Int(referenceCount) {
      guard data.count >= cursor + 12,
        let reference = data.uint32(at: cursor),
        let duration = data.uint32(at: cursor + 4)
      else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      guard reference & 0x8000_0000 == 0 else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      let byteCount = Int(reference & 0x7fff_ffff)
      guard byteCount > 0, duration > 0 else {
        throw LivePlaybackFailure.invalidPlaylist
      }
      references.append(
        LiveProviderSegmentReference(
          byteCount: byteCount,
          duration: TimeInterval(duration) / TimeInterval(timescale)
        )
      )
      cursor += 12
    }
    guard !references.isEmpty,
      firstOffset <= UInt64(Int64.max)
    else {
      throw LivePlaybackFailure.invalidPlaylist
    }
    return Self(
      firstOffset: Int64(firstOffset),
      references: references
    )
  }
}

private extension Data {
  func byte(at offset: Int) -> UInt8? {
    guard indices.contains(offset) else { return nil }
    return self[offset]
  }

  func uint16(at offset: Int) -> UInt16? {
    guard offset >= 0, count >= offset + 2 else { return nil }
    return (UInt16(self[offset]) << 8)
      | UInt16(self[offset + 1])
  }

  func uint32(at offset: Int) -> UInt32? {
    guard offset >= 0, count >= offset + 4 else { return nil }
    return (UInt32(self[offset]) << 24)
      | (UInt32(self[offset + 1]) << 16)
      | (UInt32(self[offset + 2]) << 8)
      | UInt32(self[offset + 3])
  }

  func uint64(at offset: Int) -> UInt64? {
    guard let high = uint32(at: offset),
      let low = uint32(at: offset + 4)
    else {
      return nil
    }
    return (UInt64(high) << 32) | UInt64(low)
  }
}
