import Foundation

extension RootCoordinator {
  func reconnectIfNeeded() async {
    guard isUsingOfflineSession,
      let server = selectedServer,
      let baseURL = server.baseURL
    else {
      return
    }
    do {
      let metadata = try await dependencies.serverProbeService.probe(
        baseURL: baseURL
      )
      guard selectedServer?.id == server.id,
        let snapshot = dependencies.sessionStore.session(
          forServerID: server.id
        ),
        let token = dependencies.sessionStore.accessToken(
          forServerID: server.id
        )
      else {
        return
      }
      let result = try await dependencies.authService.restoreSession(
        snapshot: snapshot,
        accessToken: token
      )
      guard selectedServer?.id == server.id else { return }
      instance = metadata
      dependencies.serviceSelection.configure(
        supportedServiceIDs: metadata.supportedServices
      )
      dependencies.pushNotificationsEnabled =
        metadata.pushNotifications?.enabled == true
      completeAuthentication(result)
    } catch {
      if shouldInvalidateCachedSession(after: error) {
        dependencies.sessionStore.clearSession(forServerID: server.id)
        currentUser = nil
        isUsingOfflineSession = false
        state = .authentication
      } else {
        connectionError =
          "The instance is still unavailable. Downloads remain available offline."
      }
    }
  }

  func activate(
    _ server: ServerProfile,
    restoresSession: Bool
  ) async {
    if selectedServer?.id != server.id {
      dependencies.playbackCoordinator.endSession()
    }
    state = .booting
    connectionError = nil
    isUsingOfflineSession = false
    selectedServer = server
    dependencies.serverStore.setSelectedServerID(server.id)
    dependencies.deArrowStore.invalidatePreferences()
    guard let baseURL = server.baseURL else {
      connectionError = ServerStoreError.invalidURL.localizedDescription
      state = .serverSetup
      return
    }
    do {
      instance = try await dependencies.serverProbeService.probe(
        baseURL: baseURL
      )
      dependencies.serviceSelection.configure(
        supportedServiceIDs: instance?.supportedServices ?? [0]
      )
      dependencies.pushNotificationsEnabled =
        instance?.pushNotifications?.enabled == true
    } catch {
      if restoresSession, restoreOfflineSession(for: server) {
        connectionError =
          "The instance is unavailable. Downloads remain available offline."
        return
      }
      connectionError = error.localizedDescription
      state = .serverSetup
      return
    }
    guard restoresSession else {
      state = .authentication
      return
    }
    await restoreSession(for: server)
  }

  private func restoreSession(for server: ServerProfile) async {
    guard let snapshot = dependencies.sessionStore.session(
      forServerID: server.id
    ), let token = dependencies.sessionStore.accessToken(
      forServerID: server.id
    ) else {
      state = .authentication
      return
    }
    do {
      let result = try await dependencies.authService.restoreSession(
        snapshot: snapshot,
        accessToken: token
      )
      guard selectedServer?.id == server.id else { return }
      completeAuthentication(result)
    } catch {
      if shouldInvalidateCachedSession(after: error) {
        dependencies.sessionStore.clearSession(forServerID: server.id)
        currentUser = nil
        isUsingOfflineSession = false
        state = .authentication
      } else if restoreOfflineSession(for: server) {
        connectionError =
          "The instance is unavailable. Downloads remain available offline."
      } else {
        currentUser = nil
        isUsingOfflineSession = false
        state = .authentication
      }
    }
  }

  func completeAuthentication(_ result: AuthSessionResult) {
    guard let server = selectedServer else { return }
    if let previousSnapshot = dependencies.sessionStore.session(
      forServerID: server.id
    ), previousSnapshot.userID != result.user.id {
      dependencies.sessionStore.clearSession(forServerID: server.id)
    }
    let snapshot = SessionSnapshot(
      serverID: server.id,
      userID: result.user.id,
      accountIdentifier: result.accountIdentifier,
      publicUsername: result.user.publicUsername,
      role: result.user.role.rawValue
    )
    dependencies.sessionStore.saveSession(
      snapshot: snapshot,
      accessToken: result.accessToken
    )
    currentUser = result.user
    isUsingOfflineSession = false
    connectionError = nil
    state = .authenticated
    Task {
      await dependencies.serviceSelection.refresh()
    }
  }

  func switchAccountProfile(to profileID: String) async throws {
    guard let server = selectedServer,
      let service = dependencies.accountProfileService
    else {
      throw AccountProfileError.unavailable
    }

    let response = try await service.switchTo(id: profileID)
    let accountIdentifier = dependencies.sessionStore.session(
      forServerID: server.id
    )?.accountIdentifier
    let user = try await dependencies.authService.user(
      accessToken: response.accessToken
    )
    dependencies.playbackCoordinator.endSession()
    dependencies.notificationCenter.clear()
    completeAuthentication(
      AuthSessionResult(
        user: user,
        accountIdentifier: accountIdentifier,
        accessToken: response.accessToken
      )
    )
  }

  enum AccountProfileError: LocalizedError {
    case unavailable

    var errorDescription: String? {
      switch self {
      case .unavailable:
        return "Account profiles are unavailable on this instance."
      }
    }
  }

  @discardableResult
  private func restoreOfflineSession(
    for server: ServerProfile
  ) -> Bool {
    guard let snapshot = dependencies.sessionStore.session(
      forServerID: server.id
    ), dependencies.sessionStore.accessToken(
      forServerID: server.id
    ) != nil else {
      return false
    }
    currentUser = AuthUser(
      id: snapshot.userID,
      role: AuthRole(rawValue: snapshot.role),
      publicUsername: snapshot.publicUsername
        ?? snapshot.accountIdentifier
    )
    isUsingOfflineSession = true
    state = .authenticated
    return true
  }

  private func shouldInvalidateCachedSession(
    after error: Error
  ) -> Bool {
    guard case let NetworkError.statusCode(code, _) = error else {
      return false
    }
    return code == 401 || code == 403
  }
}
