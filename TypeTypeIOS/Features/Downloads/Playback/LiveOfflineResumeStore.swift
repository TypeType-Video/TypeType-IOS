import Foundation

// Downloads are watched without the server: their position is kept on the device.
struct LiveOfflineResumeStore {
  static let limit = 200
  private static let key = "live.offline.resume"
  let defaults: UserDefaults

  func position(for videoURL: String) -> TimeInterval? {
    guard let entry = entries[videoURL], entry.count == 2 else { return nil }
    return entry[0]
  }

  // Near the end counts as finished: the next open starts over instead of on the credits.
  func save(_ position: TimeInterval, duration: TimeInterval, for videoURL: String) {
    var stored = entries
    if position < 5 || (duration > 0 && position >= duration - 10) {
      stored[videoURL] = nil
    } else {
      stored[videoURL] = [position, Date().timeIntervalSince1970]
    }
    if stored.count > Self.limit {
      let oldest = stored.sorted { ($0.value.last ?? 0) < ($1.value.last ?? 0) }.prefix(stored.count - Self.limit)
      oldest.forEach { stored[$0.key] = nil }
    }
    defaults.set(stored, forKey: Self.key)
  }

  private var entries: [String: [Double]] {
    defaults.dictionary(forKey: Self.key) as? [String: [Double]] ?? [:]
  }
}
