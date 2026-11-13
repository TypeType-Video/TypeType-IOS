import Foundation

final class AppDependencies {
  let serverStore: ServerStore
  let sessionStore: SessionStore
  let serverProbeService: ServerProbeServiceProtocol
  let authService: AuthServiceProtocol
  let oidcService: OIDCServiceProtocol
  let resetPasswordService: ResetPasswordServiceProtocol
  let homeFeedService: HomeFeedServiceProtocol
  let recommenderFeedbackService: LiveRecommenderFeedbackServiceProtocol?
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
  let youtubeSessionService: LiveYouTubeSessionServiceProtocol?
  let deviceLinkService: LiveDeviceLinkServiceProtocol?
  let liveChatService: LiveChatService?
  let linkedAccountsService: LiveLinkedAccountsServiceProtocol?
  let allowedChannelsService: LiveAllowedChannelsServiceProtocol?
  let playbackService: LivePlaybackServiceProtocol?
  let watchProgress: LiveWatchProgressStore
  let imagePipeline: TypeTypeImagePipeline
  let orientationLock: LiveOrientationLock
  let crashReports: LiveCrashReportArchive
  let backgroundRefresh: LiveBackgroundRefreshCoordinator
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
  lazy var appPreferences = LiveAppPreferencesStore()
  @MainActor lazy var toasts = LiveToastCenter()
  @MainActor lazy var hiddenVideos = LiveHiddenVideos()
  @MainActor
  lazy var playbackPrewarmer: LivePlaybackPrewarmer? = playbackService.map {
    LivePlaybackPrewarmer(
      service: $0,
      settingsService: settingsService,
      historyService: historyService,
      appPreferences: appPreferences
    )
  }
  @MainActor
  lazy var playbackCoordinator: LivePlaybackCoordinator = {
    let coordinator = LivePlaybackCoordinator(
      settingsService: settingsService,
      appPreferences: appPreferences,
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
    playbackPrewarmer?.currentVideoURL = { [weak coordinator] in coordinator?.currentVideo?.url }
    coordinator.hiddenVideos = hiddenVideos
    return coordinator
  }()

  @MainActor
  init(
    serverStore: ServerStore,
    sessionStore: SessionStore,
    serverProbeService: ServerProbeServiceProtocol,
    authService: AuthServiceProtocol,
    oidcService: OIDCServiceProtocol,
    resetPasswordService: ResetPasswordServiceProtocol,
    homeFeedService: HomeFeedServiceProtocol,
    recommenderFeedbackService: LiveRecommenderFeedbackServiceProtocol? = nil,
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
    youtubeSessionService: LiveYouTubeSessionServiceProtocol? = nil,
    deviceLinkService: LiveDeviceLinkServiceProtocol? = nil,
    liveChatService: LiveChatService? = nil,
    linkedAccountsService: LiveLinkedAccountsServiceProtocol? = nil,
    allowedChannelsService: LiveAllowedChannelsServiceProtocol? = nil,
    playbackService: LivePlaybackServiceProtocol? = nil,
    watchProgress: LiveWatchProgressStore = LiveWatchProgressStore(),
    imagePipeline: TypeTypeImagePipeline = TypeTypeImagePipeline(),
    orientationLock: LiveOrientationLock,
    backgroundRefresh: LiveBackgroundRefreshCoordinator,
    crashReports: LiveCrashReportArchive = LiveCrashReportArchive()
  ) {
    self.serverStore = serverStore
    self.sessionStore = sessionStore
    self.serverProbeService = serverProbeService
    self.authService = authService
    self.oidcService = oidcService
    self.resetPasswordService = resetPasswordService
    self.homeFeedService = homeFeedService
    self.recommenderFeedbackService = recommenderFeedbackService
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
    self.deviceLinkService = deviceLinkService
    self.liveChatService = liveChatService
    self.linkedAccountsService = linkedAccountsService
    self.allowedChannelsService = allowedChannelsService
    self.playbackService = playbackService
    self.watchProgress = watchProgress
    self.imagePipeline = imagePipeline
    self.orientationLock = orientationLock
    self.crashReports = crashReports
    self.backgroundRefresh = backgroundRefresh
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
    hiddenVideos.clear()
  }
}
