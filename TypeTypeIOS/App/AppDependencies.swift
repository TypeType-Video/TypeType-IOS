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
  let accountProfileService: LiveAccountProfileServiceProtocol?
  let settingsService: LiveSettingsServiceProtocol
  let serviceSelection: LiveServiceSelection
  let notificationsService: LiveNotificationsServiceProtocol
  let pushNotificationsService: LivePushNotificationsServiceProtocol?
  let rssFeedService: LiveRssFeedServiceProtocol?
  let notificationCenter: LiveNotificationCenter
  lazy var notificationPermissionManager: LiveNotificationPermissionManaging =
    LiveNotificationPermissionService()
  var pushNotificationsEnabled = false
  var rssEnabled = false
  let sessionActivityService: LiveSessionActivityServiceProtocol
  let adminService: LiveAdminServiceProtocol
  let adminAccessService: LiveAdminAccessServiceProtocol
  let contentControlsService: LiveContentControlsServiceProtocol
  let bugReportsService: LiveBugReportsServiceProtocol
  let diagnosticsStore: LiveDiagnosticsStore
  let importService: LiveImportServiceProtocol
  let portabilityService: LivePortabilityServiceProtocol
  let versionService: LiveVersionServiceProtocol
  let youtubeSessionService: LiveYouTubeSessionServiceProtocol
  let playbackService: LivePlaybackServiceProtocol?
  lazy var connectivityMonitor = LiveConnectivityMonitor()
  @MainActor
  lazy var downloadCenter: LiveDownloadCenter = {
    LiveDownloadCenter(
      service: downloaderService,
      scopeProvider: { [weak self] in
        guard let self,
          let serverID = serverStore.selectedServerID(),
          let session = sessionStore.session(forServerID: serverID)
        else {
          return nil
        }
        return LiveDownloadScope(
          serverID: serverID,
          accountID: session.userID
        )
      }
    )
  }()
  @MainActor
  lazy var playbackPrewarmer: LivePlaybackPrewarmer? = playbackService.map {
    LivePlaybackPrewarmer(
      service: $0,
      settingsService: settingsService,
      historyService: historyService
    )
  }
  @MainActor
  lazy var playbackCoordinator: LivePlaybackCoordinator = {
    let coordinator = LivePlaybackCoordinator(
      settingsService: settingsService,
      scopeProvider: { [weak self] in
        guard let self,
          let serverID = serverStore.selectedServerID(),
          let session = sessionStore.session(forServerID: serverID)
        else {
          return nil
        }
        return LivePlaybackScope(
          serverID: serverID,
          accountID: session.userID
        )
      },
      playerFactory: { [unowned self] video, autoplay in
        LivePlayerController(
          video: video,
          dependencies: self,
          autoplay: autoplay
        )
      }
    )
    coordinator.prewarmer = playbackPrewarmer
    return coordinator
  }()

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
    accountProfileService: LiveAccountProfileServiceProtocol? = nil,
    settingsService: LiveSettingsServiceProtocol,
    serviceSelection: LiveServiceSelection,
    notificationsService: LiveNotificationsServiceProtocol,
    pushNotificationsService: LivePushNotificationsServiceProtocol? = nil,
    rssFeedService: LiveRssFeedServiceProtocol? = nil,
    notificationCenter: LiveNotificationCenter,
    sessionActivityService: LiveSessionActivityServiceProtocol,
    adminService: LiveAdminServiceProtocol,
    adminAccessService: LiveAdminAccessServiceProtocol,
    contentControlsService: LiveContentControlsServiceProtocol,
    bugReportsService: LiveBugReportsServiceProtocol,
    diagnosticsStore: LiveDiagnosticsStore = LiveDiagnosticsStore(),
    importService: LiveImportServiceProtocol,
    portabilityService: LivePortabilityServiceProtocol = LivePortabilityNoopService(),
    versionService: LiveVersionServiceProtocol = LiveVersionUnavailableService(),
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
    self.accountProfileService = accountProfileService
    self.settingsService = settingsService
    self.serviceSelection = serviceSelection
    self.notificationsService = notificationsService
    self.pushNotificationsService = pushNotificationsService
    self.rssFeedService = rssFeedService
    self.notificationCenter = notificationCenter
    self.sessionActivityService = sessionActivityService
    self.adminService = adminService
    self.adminAccessService = adminAccessService
    self.contentControlsService = contentControlsService
    self.bugReportsService = bugReportsService
    self.diagnosticsStore = diagnosticsStore
    self.importService = importService
    self.portabilityService = portabilityService
    self.versionService = versionService
    self.youtubeSessionService = youtubeSessionService
    self.playbackService = playbackService
  }

  func diagnosticScope() -> LiveDiagnosticScope? {
    guard let serverID = serverStore.selectedServerID(),
      let session = sessionStore.session(forServerID: serverID)
    else {
      return nil
    }
    return LiveDiagnosticScope(
      serverID: serverID,
      accountID: session.userID
    )
  }
}

@MainActor
extension AppDependencies {
  func invalidateIdentityScopedRuntimeState() {
    playbackCoordinator.endSession()
    notificationCenter.clear()
    deArrowStore.invalidatePreferences()
    downloadCenter.cancelTracking()
  }
}
