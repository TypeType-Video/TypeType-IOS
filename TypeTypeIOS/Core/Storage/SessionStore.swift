import Foundation

final class SessionStore {
  private let defaults: UserDefaults
  private let keychain: KeychainService
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()
  private let tokenLock = NSLock()
  private var memoryTokens: [String: String] = [:]

  init(defaults: UserDefaults = .standard, keychain: KeychainService) {
    self.defaults = defaults
    self.keychain = keychain
  }

  func session(forServerID serverID: String) -> SessionSnapshot? {
    registry()[serverID]
  }

  func accessToken(forServerID serverID: String) -> String? {
    guard let snapshot = session(forServerID: serverID) else { return nil }
    if let token = tokenLock.withLock({
      memoryTokens[serverID]
    }) {
      return token
    }
    guard let token = accessToken(for: snapshot) else { return nil }
    tokenLock.withLock {
      memoryTokens[serverID] = token
    }
    return token
  }

  func updateAccessToken(_ accessToken: String, forServerID serverID: String) -> Bool {
    guard let snapshot = session(forServerID: serverID) else { return false }
    let refreshedSnapshot = SessionSnapshot(
      serverID: snapshot.serverID,
      userID: snapshot.userID,
      accountIdentifier: snapshot.accountIdentifier,
      publicUsername: snapshot.publicUsername,
      role: snapshot.role
    )
    var snapshots = registry()
    snapshots[serverID] = refreshedSnapshot
    persistRegistry(snapshots)
    tokenLock.withLock {
      memoryTokens[serverID] = accessToken
    }
    return keychain.set(
      accessToken,
      for: tokenAccount(for: refreshedSnapshot)
    )
  }

  func refreshToken(forServerID serverID: String) -> String? {
    keychain.get(refreshAccount(forServerID: serverID))
  }

  func setRefreshToken(_ token: String?, forServerID serverID: String) {
    if let token {
      _ = keychain.set(token, for: refreshAccount(forServerID: serverID))
    } else {
      _ = keychain.remove(refreshAccount(forServerID: serverID))
    }
  }

  func hasActiveSession(serverID: String) -> Bool {
    accessToken(forServerID: serverID) != nil
  }

  func saveSession(snapshot: SessionSnapshot, accessToken: String) {
    var snapshots = registry()
    snapshots[snapshot.serverID] = snapshot
    persistRegistry(snapshots)
    tokenLock.withLock {
      memoryTokens[snapshot.serverID] = accessToken
    }
    _ = keychain.set(accessToken, for: tokenAccount(for: snapshot))
  }

  func clearSession(forServerID serverID: String) {
    _ = tokenLock.withLock {
      memoryTokens.removeValue(forKey: serverID)
    }
    setRefreshToken(nil, forServerID: serverID)
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
    tokenLock.withLock {
      memoryTokens.removeAll()
    }
    for (serverID, snapshot) in registry() {
      _ = keychain.remove(tokenAccount(for: snapshot))
      setRefreshToken(nil, forServerID: serverID)
    }
    defaults.removeObject(forKey: AppConfig.sessionRegistryKey)
  }

  private func registry() -> [String: SessionSnapshot] {
    guard let data = defaults.data(forKey: AppConfig.sessionRegistryKey) else { return [:] }
    return (try? decoder.decode([String: SessionSnapshot].self, from: data)) ?? [:]
  }

  private func persistRegistry(_ snapshots: [String: SessionSnapshot]) {
    do {
      defaults.set(try encoder.encode(snapshots), forKey: AppConfig.sessionRegistryKey)
    } catch {
      AppLogger.app.failure("Saving the sessions", error)
    }
  }

  private func accessToken(for snapshot: SessionSnapshot) -> String? {
    keychain.get(tokenAccount(for: snapshot))
  }

  private func refreshAccount(forServerID serverID: String) -> String {
    "\(AppConfig.keychainTokenPrefix).refresh.\(serverID)"
  }

  private func tokenAccount(for snapshot: SessionSnapshot) -> String {
    "\(AppConfig.keychainTokenPrefix).\(snapshot.serverID).\(snapshot.userID)"
  }
}
