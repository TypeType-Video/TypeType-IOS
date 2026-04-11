import Foundation

final class SessionStore {
  private let defaults: UserDefaults
  private let keychain: KeychainService
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init(defaults: UserDefaults = .standard, keychain: KeychainService) {
    self.defaults = defaults
    self.keychain = keychain
  }

  func session(forServerID serverID: String) -> SessionSnapshot? {
    registry()[serverID]
  }

  func accessToken(forServerID serverID: String) -> String? {
    guard let snapshot = session(forServerID: serverID) else { return nil }
    return accessToken(for: snapshot)
  }

  func hasActiveSession(serverID: String) -> Bool {
    accessToken(forServerID: serverID) != nil
  }

  func saveSession(snapshot: SessionSnapshot, accessToken: String) {
    var snapshots = registry()
    snapshots[snapshot.serverID] = snapshot
    persistRegistry(snapshots)
    _ = keychain.set(accessToken, for: tokenAccount(for: snapshot))
  }

  func clearSession(forServerID serverID: String) {
    guard let snapshot = session(forServerID: serverID) else {
      var snapshots = registry()
      snapshots.removeValue(forKey: serverID)
      persistRegistry(snapshots)
      return
    }

    _ = keychain.remove(tokenAccount(for: snapshot))
    var snapshots = registry()
    snapshots.removeValue(forKey: serverID)
    persistRegistry(snapshots)
  }

  func clearAllSessions() {
    for (_, snapshot) in registry() {
      _ = keychain.remove(tokenAccount(for: snapshot))
    }
    defaults.removeObject(forKey: AppConfig.sessionRegistryKey)
  }

  private func registry() -> [String: SessionSnapshot] {
    guard let data = defaults.data(forKey: AppConfig.sessionRegistryKey) else { return [:] }
    return (try? decoder.decode([String: SessionSnapshot].self, from: data)) ?? [:]
  }

  private func persistRegistry(_ snapshots: [String: SessionSnapshot]) {
    guard let data = try? encoder.encode(snapshots) else { return }
    defaults.set(data, forKey: AppConfig.sessionRegistryKey)
  }

  private func accessToken(for snapshot: SessionSnapshot) -> String? {
    keychain.get(tokenAccount(for: snapshot))
  }

  private func tokenAccount(for snapshot: SessionSnapshot) -> String {
    "\(AppConfig.keychainTokenPrefix).\(snapshot.serverID).\(snapshot.userID)"
  }
}
