import Foundation

struct LiveSavedAccount: Codable, Equatable, Identifiable {
  let userID: String
  let accountIdentifier: String?
  let publicUsername: String?
  let role: String

  var id: String { userID }
}

final class LiveSavedAccountStore {
  private static let storageKey = "typetype.saved-accounts.v1"

  private let defaults: UserDefaults
  private let keychain: KeychainService

  init(defaults: UserDefaults, keychain: KeychainService) {
    self.defaults = defaults
    self.keychain = keychain
  }

  func accounts(serverID: String) -> [LiveSavedAccount] {
    registry()[serverID] ?? []
  }

  func remember(_ snapshot: SessionSnapshot, refreshToken: String?) {
    var all = registry()
    var list = all[snapshot.serverID] ?? []
    let account = LiveSavedAccount(
      userID: snapshot.userID,
      accountIdentifier: snapshot.accountIdentifier,
      publicUsername: snapshot.publicUsername,
      role: snapshot.role
    )
    if let index = list.firstIndex(where: { $0.userID == snapshot.userID }) {
      list[index] = account
    } else {
      list.append(account)
    }
    all[snapshot.serverID] = list
    persist(all)
    if let refreshToken {
      storeRefreshToken(refreshToken, serverID: snapshot.serverID, userID: snapshot.userID)
    }
  }

  func storeRefreshToken(_ token: String, serverID: String, userID: String) {
    _ = keychain.set(token, for: tokenAccount(serverID: serverID, userID: userID))
  }

  func refreshToken(serverID: String, userID: String) -> String? {
    keychain.get(tokenAccount(serverID: serverID, userID: userID))
  }

  func forget(serverID: String, userID: String) {
    var all = registry()
    all[serverID]?.removeAll { $0.userID == userID }
    persist(all)
    _ = keychain.remove(tokenAccount(serverID: serverID, userID: userID))
  }

  func forgetAll(serverID: String) {
    for account in accounts(serverID: serverID) {
      forget(serverID: serverID, userID: account.userID)
    }
  }

  private func registry() -> [String: [LiveSavedAccount]] {
    guard let data = defaults.data(forKey: Self.storageKey) else { return [:] }
    do {
      return try JSONDecoder().decode([String: [LiveSavedAccount]].self, from: data)
    } catch {
      AppLogger.app.failure("Reading the saved accounts", error)
      return [:]
    }
  }

  private func persist(_ all: [String: [LiveSavedAccount]]) {
    do {
      defaults.set(try JSONEncoder().encode(all), forKey: Self.storageKey)
    } catch {
      AppLogger.app.failure("Saving the saved accounts", error)
    }
  }

  private func tokenAccount(serverID: String, userID: String) -> String {
    "\(AppConfig.keychainTokenPrefix).saved.\(serverID).\(userID)"
  }
}
