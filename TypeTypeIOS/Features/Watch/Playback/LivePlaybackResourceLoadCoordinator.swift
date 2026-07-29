import Foundation

final class LivePlaybackResourceLoadCoordinator: @unchecked Sendable {
  typealias Resource = LivePlaybackHTTPServer.Resource

  private struct Entry {
    let id: UUID
    let task: Task<Resource, Error>
  }

  private let lock = NSLock()
  private var inFlight: [String: Entry] = [:]

  func value(
    for key: String,
    operation: @escaping @Sendable () async throws -> Resource
  ) async throws -> Resource {
    try Task.checkCancellation()
    let entry = lock.withLock { () -> Entry in
      if let entry = inFlight[key] {
        return entry
      }
      let entry = Entry(
        id: UUID(),
        task: Task {
          try await operation()
        }
      )
      inFlight[key] = entry
      return entry
    }

    do {
      let value = try await entry.task.value
      removeEntry(for: key, id: entry.id)
      return value
    } catch {
      removeEntry(for: key, id: entry.id)
      throw error
    }
  }

  func cancelAll() {
    let tasks = lock.withLock { () -> [Task<Resource, Error>] in
      let tasks = inFlight.values.map(\.task)
      inFlight.removeAll()
      return tasks
    }
    tasks.forEach { $0.cancel() }
  }

  var activeLoadCount: Int {
    lock.withLock { inFlight.count }
  }

  private func removeEntry(for key: String, id: UUID) {
    lock.withLock {
      guard inFlight[key]?.id == id else { return }
      inFlight[key] = nil
    }
  }
}
