import Foundation
import TypeTypePlayerKit

// A failed load is forgotten, not cached: one network blip would fail every later segment.
actor LiveProviderSegmentIndexes {
  typealias Loader = @Sendable (MP4TrackKind) async throws -> [MP4IndexEntry]

  private let load: Loader
  private var loaded: [MP4TrackKind: [MP4IndexEntry]] = [:]
  private var running: [MP4TrackKind: Task<[MP4IndexEntry], Error>] = [:]

  init(kinds: [MP4TrackKind], load: @escaping Loader) {
    self.load = load
    for kind in kinds {
      running[kind] = Task { try await load(kind) }
    }
  }

  deinit {
    running.values.forEach { $0.cancel() }
  }

  func entries(_ kind: MP4TrackKind) async throws -> [MP4IndexEntry] {
    if let entries = loaded[kind] { return entries }
    let task = running[kind] ?? Task { [load] in try await load(kind) }
    running[kind] = task
    do {
      let entries = try await task.value
      loaded[kind] = entries
      running[kind] = nil
      return entries
    } catch {
      if running[kind] == task { running[kind] = nil }
      throw error
    }
  }
}
