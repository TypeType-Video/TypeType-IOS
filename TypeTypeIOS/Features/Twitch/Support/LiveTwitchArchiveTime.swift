import Foundation

// The live plays a few seconds behind the broadcaster and its recording starts a few seconds after the stream: the
// matching moment of the recording is taken a little earlier, so it resumes just before what was seen, never after.
enum LiveTwitchArchiveTime {
  static let behind: TimeInterval = 15
  // Released this close to the live edge, the rewind stays on the live instead of opening the recording.
  static let minimumRewind: TimeInterval = 30

  static func position(startedAt: String, now: Date) -> TimeInterval? {
    guard let start = LiveTwitchFormat.date(startedAt) else { return nil }
    return max(0, now.timeIntervalSince(start) - behind)
  }

  static func rewindTarget(_ value: TimeInterval, range: TimeInterval) -> TimeInterval? {
    guard range > 0, value <= range - minimumRewind else { return nil }
    return max(0, value.rounded())
  }
}
