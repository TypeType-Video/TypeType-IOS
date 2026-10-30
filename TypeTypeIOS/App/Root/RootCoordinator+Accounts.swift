import Foundation

extension RootCoordinator {
  enum AccountSwitchError: LocalizedError {
    case signInAgain

    var errorDescription: String? {
      String(localized: "This account needs to sign in again.")
    }
  }

  var savedAccounts: [LiveSavedAccount] {
    guard let serverID = selectedServer?.id else { return [] }
    return dependencies.sessionStore.savedAccounts.accounts(serverID: serverID)
  }

  func switchAccount(to account: LiveSavedAccount) async throws {
    let store = dependencies.sessionStore
    guard let server = selectedServer, account.userID != currentUser?.id else { return }
    guard let target = store.savedAccounts.refreshToken(serverID: server.id, userID: account.userID) else {
      throw AccountSwitchError.signInAgain
    }
    let previousSnapshot = store.session(forServerID: server.id)
    let previousAccess = store.accessToken(forServerID: server.id)
    let previousRefresh = store.refreshToken(forServerID: server.id)
    store.clearSession(forServerID: server.id)
    store.setRefreshToken(target, forServerID: server.id)
    do {
      let access = try await dependencies.authService.refresh()
      let user = try await dependencies.authService.user(accessToken: access)
      dependencies.invalidateIdentityScopedRuntimeState()
      completeAuthentication(
        AuthSessionResult(user: user, accountIdentifier: account.accountIdentifier, accessToken: access)
      )
    } catch {
      store.clearSession(forServerID: server.id)
      store.setRefreshToken(previousRefresh, forServerID: server.id)
      if let previousSnapshot, let previousAccess {
        store.saveSession(snapshot: previousSnapshot, accessToken: previousAccess)
      }
      throw AccountSwitchError.signInAgain
    }
  }

  func addAccount() {
    guard let serverID = selectedServer?.id else { return }
    dependencies.playbackCoordinator.endSession()
    dependencies.invalidateIdentityScopedRuntimeState()
    dependencies.sessionStore.clearSession(forServerID: serverID)
    currentUser = nil
    isUsingOfflineSession = false
    state = .authentication
  }

  func forgetAccount(_ account: LiveSavedAccount) async {
    guard let serverID = selectedServer?.id else { return }
    if account.userID == currentUser?.id {
      await signOut()
    }
    dependencies.sessionStore.savedAccounts.forget(serverID: serverID, userID: account.userID)
    objectWillChange.send()
  }
}
