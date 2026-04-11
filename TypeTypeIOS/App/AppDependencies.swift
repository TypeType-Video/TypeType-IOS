import Foundation

final class AppDependencies {
  let keychainService: KeychainService
  let serverStore: ServerStore
  let sessionStore: SessionStore
  let serverProbeService: ServerProbeServiceProtocol
  let authService: AuthServiceProtocol

  init(
    keychainService: KeychainService,
    serverStore: ServerStore,
    sessionStore: SessionStore,
    serverProbeService: ServerProbeServiceProtocol,
    authService: AuthServiceProtocol
  ) {
    self.keychainService = keychainService
    self.serverStore = serverStore
    self.sessionStore = sessionStore
    self.serverProbeService = serverProbeService
    self.authService = authService
  }

  static let live: AppDependencies = {
    let keychain = SecureKeychainService()
    let serverStore = ServerStore()
    let sessionStore = SessionStore(keychain: keychain)
    let probeService = ServerProbeService()
    let client = URLSessionAPIClient(
      serverURLProvider: { serverStore.selectedServer()?.baseURL },
      accessTokenProvider: {
        guard let selectedID = serverStore.selectedServerID() else { return nil }
        return sessionStore.accessToken(forServerID: selectedID)
      }
    )
    let authService = AuthService(apiClient: client)
    return AppDependencies(
      keychainService: keychain,
      serverStore: serverStore,
      sessionStore: sessionStore,
      serverProbeService: probeService,
      authService: authService
    )
  }()
}
