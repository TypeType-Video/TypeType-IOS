import Foundation

/// Short-lived, thread-safe cache for stream metadata.
final class LiveStreamMetadataCache: @unchecked Sendable {
  private struct Entry {
    let stream: LivePlaybackStream
    let date: Date
  }

  private let lock = NSLock()
  private var entries: [String: Entry] = [:]

  func stream(for key: String, ttl: TimeInterval) -> LivePlaybackStream? {
    lock.lock()
    defer { lock.unlock() }
    let cutoff = Date().addingTimeInterval(-ttl)
    entries = entries.filter { $0.value.date > cutoff }
    guard let entry = entries[key], entry.date > cutoff else {
      return nil
    }
    return entry.stream
  }

  func store(_ stream: LivePlaybackStream, for key: String) {
    lock.lock()
    defer { lock.unlock() }
    entries[key] = Entry(stream: stream, date: Date())
  }
}

/// Shares one running request between callers asking for the same stream,
/// so a touch-down prewarm and the player opening never fetch it twice.
actor LiveStreamRequests {
  private var running: [String: Task<LivePlaybackStream, Error>] = [:]

  func value(
    for key: String,
    load: @escaping @Sendable () async throws -> LivePlaybackStream
  ) async throws -> LivePlaybackStream {
    if let task = running[key] { return try await task.value }
    let task = Task { try await load() }
    running[key] = task
    defer {
      if running[key] == task { running[key] = nil }
    }
    return try await task.value
  }

  func discard(_ key: String) {
    running.removeValue(forKey: key)?.cancel()
  }
}
