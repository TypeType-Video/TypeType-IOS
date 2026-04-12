import Foundation

final class AppDependencies {
  let keychainService: KeychainService
  let serverStore: ServerStore
  let sessionStore: SessionStore
  let serverProbeService: ServerProbeServiceProtocol
  let authService: AuthServiceProtocol
  let resetPasswordService: ResetPasswordServiceProtocol
  let profileService: ProfileServiceProtocol
  let homeFeedService: HomeFeedServiceProtocol
  let searchService: SearchServiceProtocol
  let subscriptionsService: SubscriptionsServiceProtocol
  let watchService: WatchServiceProtocol
  let watchProgressService: WatchProgressServiceProtocol
  let watchActionsService: WatchActionsServiceProtocol
  let adminService: AdminServiceProtocol
  let libraryService: LibraryServiceProtocol
  let userSettingsService: UserSettingsServiceProtocol
  let pipePipeImportService: PipePipeImportServiceProtocol
  let youtubeImportService: YoutubeImportServiceProtocol

  init(
    keychainService: KeychainService,
    serverStore: ServerStore,
    sessionStore: SessionStore,
    serverProbeService: ServerProbeServiceProtocol,
    authService: AuthServiceProtocol,
    resetPasswordService: ResetPasswordServiceProtocol,
    profileService: ProfileServiceProtocol,
    homeFeedService: HomeFeedServiceProtocol,
    searchService: SearchServiceProtocol,
    subscriptionsService: SubscriptionsServiceProtocol,
    watchService: WatchServiceProtocol,
    watchProgressService: WatchProgressServiceProtocol,
    watchActionsService: WatchActionsServiceProtocol,
    adminService: AdminServiceProtocol,
    libraryService: LibraryServiceProtocol,
    userSettingsService: UserSettingsServiceProtocol,
    pipePipeImportService: PipePipeImportServiceProtocol,
    youtubeImportService: YoutubeImportServiceProtocol
  ) {
    self.keychainService = keychainService
    self.serverStore = serverStore
    self.sessionStore = sessionStore
    self.serverProbeService = serverProbeService
    self.authService = authService
    self.resetPasswordService = resetPasswordService
    self.profileService = profileService
    self.homeFeedService = homeFeedService
    self.searchService = searchService
    self.subscriptionsService = subscriptionsService
    self.watchService = watchService
    self.watchProgressService = watchProgressService
    self.watchActionsService = watchActionsService
    self.adminService = adminService
    self.libraryService = libraryService
    self.userSettingsService = userSettingsService
    self.pipePipeImportService = pipePipeImportService
    self.youtubeImportService = youtubeImportService
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
    let resetPasswordService = ResetPasswordService(apiClient: client)
    let profileService = ProfileService(apiClient: client)
    client.setTokenRefreshHandler { staleToken in
      let refreshedToken = try await authService.refresh(using: staleToken)
      guard let selectedID = serverStore.selectedServerID() else { return nil }
      let didStore = sessionStore.updateAccessToken(refreshedToken, forServerID: selectedID)
      return didStore ? refreshedToken : nil
    }
    let homeFeedService = HomeFeedService(apiClient: client)
    let searchService = SearchService(apiClient: client)
    let subscriptionsService = SubscriptionsService(apiClient: client)
    let watchService = WatchService(apiClient: client)
    let watchProgressService = WatchProgressService(apiClient: client)
    let watchActionsService = WatchActionsService(apiClient: client)
    let adminService = AdminService(apiClient: client)
    let libraryService = LibraryService(apiClient: client)
    let userSettingsService = UserSettingsService(apiClient: client)
    let pipePipeImportService = PipePipeImportService(apiClient: client)
    let youtubeImportService = YoutubeImportService(apiClient: client)
    return AppDependencies(
      keychainService: keychain,
      serverStore: serverStore,
      sessionStore: sessionStore,
      serverProbeService: probeService,
      authService: authService,
      resetPasswordService: resetPasswordService,
      profileService: profileService,
      homeFeedService: homeFeedService,
      searchService: searchService,
      subscriptionsService: subscriptionsService,
      watchService: watchService,
      watchProgressService: watchProgressService,
      watchActionsService: watchActionsService,
      adminService: adminService,
      libraryService: libraryService,
      userSettingsService: userSettingsService,
      pipePipeImportService: pipePipeImportService,
      youtubeImportService: youtubeImportService
    )
  }()
}
