import Foundation

extension AppDependencies {
  @MainActor
  static func live() -> AppDependencies {
    let serverStore = ServerStore()
    // Relative server image references (avatars) resolve against the active
    // instance, mirroring the Android client.
    LiveImageURLResolver.baseURLProvider = {
      serverStore.selectedServer()?.baseURL
    }
    let sessionStore = SessionStore(
      keychain: SecureKeychainService()
    )
#if DEBUG
    if CommandLine.arguments.contains("--typetype-reset-live-state") {
      sessionStore.clearAllSessions()
      LiveDownloadCenter.resetPersistentState()
      LiveDiagnosticsStore.resetPersistentState()
      UserDefaults.standard.removeObject(
        forKey: AppConfig.serverListKey
      )
      UserDefaults.standard.removeObject(
        forKey: AppConfig.selectedServerIDKey
      )
      UserDefaults.standard.removeObject(
        forKey: AppConfig.playbackQueueRegistryKey
      )
    }
#endif
    let diagnosticsStore = LiveDiagnosticsStore()
    let client = URLSessionAPIClient(
      serverURLProvider: {
        serverStore.selectedServer()?.baseURL
      },
      accessTokenProvider: {
        guard let serverID = serverStore.selectedServerID() else {
          return nil
        }
        return sessionStore.accessToken(forServerID: serverID)
      },
      diagnosticsStore: diagnosticsStore,
      diagnosticScopeProvider: {
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
    )
    let authService = AuthService(
      apiClient: client,
      refreshTokenProvider: {
        serverStore.selectedServerID().flatMap { sessionStore.refreshToken(forServerID: $0) }
      }
    )
    let accountProfileService = LiveAccountProfileService(apiClient: client)
    client.setRefreshCookieObserver { token in
      guard let serverID = serverStore.selectedServerID() else { return }
      sessionStore.setRefreshToken(token, forServerID: serverID)
    }
    client.setTokenRefreshHandler { _ in
      let serverID = serverStore.selectedServerID()
      let token: String
      do {
        token = try await authService.refresh()
      } catch let NetworkError.statusCode(code, message) where code == 401 {
        if let serverID {
          NotificationCenter.default.post(
            name: .liveSessionExpired,
            object: nil,
            userInfo: [LiveSessionExpiry.serverIDKey: serverID]
          )
        }
        throw NetworkError.statusCode(code, message)
      }
      guard let serverID,
        sessionStore.updateAccessToken(token, forServerID: serverID)
      else {
        return nil
      }
      return token
    }
    let settingsService = LiveSettingsService(apiClient: client)
    let notificationsService = LiveNotificationsService(apiClient: client)
    let pushNotificationsService = LivePushNotificationsService(
      apiClient: client
    )
    let rssFeedService = LiveRssFeedService(apiClient: client)
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
      accountProfileService: accountProfileService,
      settingsService: settingsService,
      serviceSelection: LiveServiceSelection(
        settingsService: settingsService
      ),
      notificationsService: notificationsService,
      pushNotificationsService: pushNotificationsService,
      rssFeedService: rssFeedService,
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
      bugReportsService: LiveBugReportsService(
        apiClient: client,
        diagnosticsStore: diagnosticsStore,
        diagnosticScopeProvider: {
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
      ),
      diagnosticsStore: diagnosticsStore,
      importService: LiveImportService(apiClient: client),
      portabilityService: LivePortabilityService(apiClient: client),
      versionService: LiveVersionService(apiClient: client),
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
