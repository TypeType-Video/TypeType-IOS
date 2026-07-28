import Foundation

final class LivePlaybackQueueStore {
  private struct Record: Codable {
    let scope: LivePlaybackScope
    let snapshot: LivePlaybackQueueSnapshot
  }

  private let defaults: UserDefaults
  private let key: String
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init(
    defaults: UserDefaults = .standard,
    key: String = AppConfig.playbackQueueRegistryKey
  ) {
    self.defaults = defaults
    self.key = key
  }

  func load(for scope: LivePlaybackScope) -> LivePlaybackQueueSnapshot? {
    guard let record = records().last(where: { $0.scope == scope }),
      Self.isValid(record.snapshot)
    else {
      clear(scope)
      return nil
    }
    return record.snapshot
  }

  func save(
    _ snapshot: LivePlaybackQueueSnapshot,
    for scope: LivePlaybackScope
  ) {
    guard Self.isValid(snapshot) else {
      clear(scope)
      return
    }
    var values = records().filter { $0.scope != scope }
    values.append(Record(scope: scope, snapshot: snapshot))
    persist(values)
  }

  func clear(_ scope: LivePlaybackScope) {
    persist(records().filter { $0.scope != scope })
  }

  func clear(serverID: String) {
    persist(records().filter { $0.scope.serverID != serverID })
  }

  private func records() -> [Record] {
    guard let data = defaults.data(forKey: key) else { return [] }
    return (try? decoder.decode([Record].self, from: data)) ?? []
  }

  private func persist(_ records: [Record]) {
    guard !records.isEmpty else {
      defaults.removeObject(forKey: key)
      return
    }
    guard let data = try? encoder.encode(records) else { return }
    defaults.set(data, forKey: key)
  }

  private static func isValid(
    _ snapshot: LivePlaybackQueueSnapshot
  ) -> Bool {
    guard snapshot.isActive,
      snapshot.videos.allSatisfy({
        !$0.url.trimmingCharacters(
          in: .whitespacesAndNewlines
        ).isEmpty
      })
    else {
      return false
    }
    return Set(snapshot.videos.map(\.url)).count
      == snapshot.videos.count
  }
}
