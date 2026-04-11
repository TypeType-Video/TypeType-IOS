import Foundation

final class AppDependencies {
  let keychainService: KeychainService
  let serverStore: ServerStore
  let sessionStore: SessionStore
  let serverProbeService: ServerProbeServiceProtocol
  let authService: AuthServiceProtocol
  let homeFeedService: HomeFeedServiceProtocol
  let searchService: SearchServiceProtocol
  let watchService: WatchServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol
  let adminService: AdminServiceProtocol
  let libraryService: LibraryServiceProtocol
  let userSettingsService: UserSettingsServiceProtocol

  init(
    keychainService: KeychainService,
    serverStore: ServerStore,
    sessionStore: SessionStore,
    serverProbeService: ServerProbeServiceProtocol,
    authService: AuthServiceProtocol,
    homeFeedService: HomeFeedServiceProtocol,
    searchService: SearchServiceProtocol,
    watchService: WatchServiceProtocol,
    watchActionsService: WatchActionsServiceProtocol,
    adminService: AdminServiceProtocol,
    libraryService: LibraryServiceProtocol,
    userSettingsService: UserSettingsServiceProtocol
  ) {
    self.keychainService = keychainService
    self.serverStore = serverStore
    self.sessionStore = sessionStore
    self.serverProbeService = serverProbeService
    self.authService = authService
    self.homeFeedService = homeFeedService
    self.searchService = searchService
    self.watchService = watchService
    self.watchActionsService = watchActionsService
    self.adminService = adminService
    self.libraryService = libraryService
    self.userSettingsService = userSettingsService
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
    let homeFeedService = HomeFeedService(apiClient: client)
    let searchService = SearchService(apiClient: client)
    let watchService = WatchService(apiClient: client)
    let watchActionsService = WatchActionsService(apiClient: client)
    let adminService = AdminService(apiClient: client)
    let libraryService = LibraryService(apiClient: client)
    let userSettingsService = UserSettingsService(apiClient: client)
    return AppDependencies(
      keychainService: keychain,
      serverStore: serverStore,
      sessionStore: sessionStore,
      serverProbeService: probeService,
      authService: authService,
      homeFeedService: homeFeedService,
      searchService: searchService,
      watchService: watchService,
      watchActionsService: watchActionsService,
      adminService: adminService,
      libraryService: libraryService,
      userSettingsService: userSettingsService
    )
  }()
}
