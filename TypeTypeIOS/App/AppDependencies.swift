import Foundation

final class AppDependencies {
  let serverStore: ServerStore
  let sessionStore: SessionStore
  let serverProbeService: ServerProbeServiceProtocol
  let authService: AuthServiceProtocol
  let oidcService: OIDCServiceProtocol
  let resetPasswordService: ResetPasswordServiceProtocol
  let homeFeedService: HomeFeedServiceProtocol
  let commentsService: LiveCommentsServiceProtocol
  let downloaderService: LiveDownloaderServiceProtocol
  let deArrowStore: LiveDeArrowStore
  let searchService: LiveSearchServiceProtocol
  let searchHistoryService: LiveSearchHistoryServiceProtocol
  let channelService: LiveChannelServiceProtocol
  let subscriptionsService: LiveSubscriptionsServiceProtocol
  let historyService: LiveHistoryServiceProtocol
  let libraryService: LiveLibraryServiceProtocol
  let playlistsService: LivePlaylistsServiceProtocol
  let profileService: LiveProfileServiceProtocol
  let settingsService: LiveSettingsServiceProtocol
  let serviceSelection: LiveServiceSelection
  let notificationsService: LiveNotificationsServiceProtocol
  let notificationCenter: LiveNotificationCenter
  let sessionActivityService: LiveSessionActivityServiceProtocol
  let adminService: LiveAdminServiceProtocol
  let adminAccessService: LiveAdminAccessServiceProtocol
  let contentControlsService: LiveContentControlsServiceProtocol
  let bugReportsService: LiveBugReportsServiceProtocol
  let importService: LiveImportServiceProtocol
  let youtubeSessionService: LiveYouTubeSessionServiceProtocol
  let playbackService: LivePlaybackServiceProtocol?

  init(
    serverStore: ServerStore,
    sessionStore: SessionStore,
    serverProbeService: ServerProbeServiceProtocol,
    authService: AuthServiceProtocol,
    oidcService: OIDCServiceProtocol,
    resetPasswordService: ResetPasswordServiceProtocol,
    homeFeedService: HomeFeedServiceProtocol,
    commentsService: LiveCommentsServiceProtocol,
    downloaderService: LiveDownloaderServiceProtocol,
    deArrowStore: LiveDeArrowStore,
    searchService: LiveSearchServiceProtocol,
    searchHistoryService: LiveSearchHistoryServiceProtocol,
    channelService: LiveChannelServiceProtocol,
    subscriptionsService: LiveSubscriptionsServiceProtocol,
    historyService: LiveHistoryServiceProtocol,
    libraryService: LiveLibraryServiceProtocol,
    playlistsService: LivePlaylistsServiceProtocol,
    profileService: LiveProfileServiceProtocol,
    settingsService: LiveSettingsServiceProtocol,
    serviceSelection: LiveServiceSelection,
    notificationsService: LiveNotificationsServiceProtocol,
    notificationCenter: LiveNotificationCenter,
    sessionActivityService: LiveSessionActivityServiceProtocol,
    adminService: LiveAdminServiceProtocol,
    adminAccessService: LiveAdminAccessServiceProtocol,
    contentControlsService: LiveContentControlsServiceProtocol,
    bugReportsService: LiveBugReportsServiceProtocol,
    importService: LiveImportServiceProtocol,
    youtubeSessionService: LiveYouTubeSessionServiceProtocol,
    playbackService: LivePlaybackServiceProtocol? = nil
  ) {
    self.serverStore = serverStore
    self.sessionStore = sessionStore
    self.serverProbeService = serverProbeService
    self.authService = authService
    self.oidcService = oidcService
    self.resetPasswordService = resetPasswordService
    self.homeFeedService = homeFeedService
    self.commentsService = commentsService
    self.downloaderService = downloaderService
    self.deArrowStore = deArrowStore
    self.searchService = searchService
    self.searchHistoryService = searchHistoryService
    self.channelService = channelService
    self.subscriptionsService = subscriptionsService
    self.historyService = historyService
    self.libraryService = libraryService
    self.playlistsService = playlistsService
    self.profileService = profileService
    self.settingsService = settingsService
    self.serviceSelection = serviceSelection
    self.notificationsService = notificationsService
    self.notificationCenter = notificationCenter
    self.sessionActivityService = sessionActivityService
    self.adminService = adminService
    self.adminAccessService = adminAccessService
    self.contentControlsService = contentControlsService
    self.bugReportsService = bugReportsService
    self.importService = importService
    self.youtubeSessionService = youtubeSessionService
    self.playbackService = playbackService
  }

  @MainActor
  static func live() -> AppDependencies {
    let serverStore = ServerStore()
    let sessionStore = SessionStore(
      keychain: SecureKeychainService()
    )
#if DEBUG
    if CommandLine.arguments.contains("--typetype-reset-live-state") {
      sessionStore.clearAllSessions()
      UserDefaults.standard.removeObject(
        forKey: AppConfig.serverListKey
      )
      UserDefaults.standard.removeObject(
        forKey: AppConfig.selectedServerIDKey
      )
    }
#endif
    let client = URLSessionAPIClient(
      serverURLProvider: {
        serverStore.selectedServer()?.baseURL
      },
      accessTokenProvider: {
        guard let serverID = serverStore.selectedServerID() else {
          return nil
        }
        return sessionStore.accessToken(forServerID: serverID)
      }
    )
    let authService = AuthService(apiClient: client)
    client.setTokenRefreshHandler { _ in
      let token = try await authService.refresh()
      guard let serverID = serverStore.selectedServerID(),
        sessionStore.updateAccessToken(token, forServerID: serverID)
      else {
        return nil
      }
      return token
    }
    let settingsService = LiveSettingsService(apiClient: client)
    let notificationsService = LiveNotificationsService(apiClient: client)
    let deArrowService = LiveDeArrowService(
      apiClient: client,
      baseURLProvider: {
        serverStore.selectedServer()?.baseURL
      }
    )
    return AppDependencies(
      serverStore: serverStore,
      sessionStore: sessionStore,
      serverProbeService: ServerProbeService(),
      authService: authService,
      oidcService: OIDCService(apiClient: client),
      resetPasswordService: ResetPasswordService(apiClient: client),
      homeFeedService: HomeFeedService(apiClient: client),
      commentsService: LiveCommentsService(apiClient: client),
      downloaderService: LiveDownloaderService(apiClient: client),
      deArrowStore: LiveDeArrowStore(
        service: deArrowService,
        settingsService: settingsService
      ),
      searchService: LiveSearchService(apiClient: client),
      searchHistoryService: LiveSearchHistoryService(apiClient: client),
      channelService: LiveChannelService(apiClient: client),
      subscriptionsService: LiveSubscriptionsService(
        apiClient: client
      ),
      historyService: LiveHistoryService(apiClient: client),
      libraryService: LiveLibraryService(apiClient: client),
      playlistsService: LivePlaylistsService(apiClient: client),
      profileService: LiveProfileService(apiClient: client),
      settingsService: settingsService,
      serviceSelection: LiveServiceSelection(
        settingsService: settingsService
      ),
      notificationsService: notificationsService,
      notificationCenter: LiveNotificationCenter(
        service: notificationsService
      ),
      sessionActivityService: LiveSessionActivityService(
        apiClient: client,
        canReport: {
          guard let serverID = serverStore.selectedServerID(),
            let session = sessionStore.session(forServerID: serverID)
          else {
            return false
          }
          return !session.userID.hasPrefix("guest:")
        }
      ),
      adminService: LiveAdminService(apiClient: client),
      adminAccessService: LiveAdminAccessService(apiClient: client),
      contentControlsService: LiveContentControlsService(apiClient: client),
      bugReportsService: LiveBugReportsService(apiClient: client),
      importService: LiveImportService(apiClient: client),
      youtubeSessionService: LiveYouTubeSessionService(apiClient: client),
      playbackService: LivePlaybackService(
        apiClient: client,
        serverURLProvider: {
          serverStore.selectedServer()?.baseURL
        }
      )
    )
  }
}
