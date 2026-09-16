import Foundation
import XCTest
@testable import TypeTypeIOS

@MainActor
final class RootCoordinatorTests: XCTestCase {
  private var defaults: UserDefaults!
  private var suiteName: String!

  override func setUp() {
    super.setUp()
    suiteName = "RootCoordinatorTests.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
    defaults = nil
    suiteName = nil
    super.tearDown()
  }

  func testConnectLoginRestoreAndLogoutLifecycle() async throws {
    let dependencies = try makeDependencies()
    let coordinator = RootCoordinator(dependencies: dependencies)

    await coordinator.bootstrap()
    XCTAssertEqual(coordinator.state, .serverSetup)

    try await coordinator.addServer(
      name: "Beta",
      urlInput: "https://beta.example.test"
    )
    XCTAssertEqual(coordinator.state, .authentication)
    XCTAssertEqual(coordinator.instance?.name, "TypeType")

    try await coordinator.login(
      identifier: "person@example.test",
      password: "secret"
    )
    XCTAssertEqual(coordinator.state, .authenticated)
    XCTAssertEqual(coordinator.currentUser?.id, "user-1")
    let serverID = try XCTUnwrap(coordinator.selectedServer?.id)
    XCTAssertEqual(
      dependencies.sessionStore.accessToken(forServerID: serverID),
      "access-1"
    )

    let restored = RootCoordinator(dependencies: dependencies)
    await restored.bootstrap()
    XCTAssertEqual(restored.state, .authenticated)
    XCTAssertEqual(restored.currentUser?.id, "user-1")

    await restored.signOut()
    XCTAssertEqual(restored.state, .authentication)
    XCTAssertNil(
      dependencies.sessionStore.session(forServerID: serverID)
    )
  }

  func testRemovingSelectedInstanceClearsAuthenticatedContext() async throws {
    let dependencies = try makeDependencies()
    let coordinator = RootCoordinator(dependencies: dependencies)
    await coordinator.bootstrap()
    try await coordinator.addServer(
      name: "Beta",
      urlInput: "https://beta.example.test"
    )
    try await coordinator.login(
      identifier: "person@example.test",
      password: "secret"
    )
    let server = try XCTUnwrap(coordinator.selectedServer)

    coordinator.showServerSetup()
    coordinator.deleteServer(server)

    XCTAssertEqual(coordinator.state, .serverSetup)
    XCTAssertNil(coordinator.selectedServer)
    XCTAssertNil(coordinator.instance)
    XCTAssertNil(coordinator.currentUser)
    XCTAssertTrue(coordinator.servers.isEmpty)
    XCTAssertNil(
      dependencies.sessionStore.session(forServerID: server.id)
    )
  }

  func testIncomingMediaLinkWaitsForAuthenticationThenConsumesOnce()
    async throws
  {
    let dependencies = try makeDependencies()
    let coordinator = RootCoordinator(dependencies: dependencies)
    let incomingURL = try XCTUnwrap(
      URL(string: "typetype://watch?v=sm9")
    )

    coordinator.receiveIncomingURL(incomingURL)
    XCTAssertNil(coordinator.consumeIncomingMediaLink())
    XCTAssertEqual(coordinator.pendingIncomingURL, incomingURL)

    await coordinator.bootstrap()
    try await coordinator.addServer(
      name: "Beta",
      urlInput: "https://beta.example.test"
    )
    try await coordinator.login(
      identifier: "person@example.test",
      password: "secret"
    )

    let link = try XCTUnwrap(coordinator.consumeIncomingMediaLink())
    guard case let .video(video) = link.destination else {
      return XCTFail("The queued link should open as a video.")
    }
    XCTAssertEqual(
      video.url,
      "https://www.nicovideo.jp/watch/sm9"
    )
    XCTAssertNil(coordinator.pendingIncomingURL)
    XCTAssertNil(coordinator.consumeIncomingMediaLink())
  }

  func testCachedSessionKeepsDownloadsReachableWhenInstanceIsOffline()
    async throws
  {
    let dependencies = try makeDependencies(
      probe: RootOfflineProbeStub()
    )
    let server = try dependencies.serverStore.makeServer(
      name: "Offline instance",
      urlInput: "https://offline.example.test"
    )
    try dependencies.serverStore.insert(server)
    dependencies.serverStore.setSelectedServerID(server.id)
    dependencies.sessionStore.saveSession(
      snapshot: SessionSnapshot(
        serverID: server.id,
        userID: "user-1",
        accountIdentifier: "person@example.test",
        publicUsername: "person",
        role: AuthRole.user.rawValue
      ),
      accessToken: "cached-token"
    )

    let coordinator = RootCoordinator(dependencies: dependencies)
    await coordinator.bootstrap()

    XCTAssertEqual(coordinator.state, .authenticated)
    XCTAssertTrue(coordinator.isUsingOfflineSession)
    XCTAssertEqual(coordinator.currentUser?.id, "user-1")
    XCTAssertEqual(coordinator.currentUser?.publicUsername, "person")
    XCTAssertNotNil(coordinator.connectionError)
  }

  func testProfileSwitchReplacesServerScopedSession() async throws {
    let profileUser = AuthUser(
      id: "profile-2",
      role: .user,
      publicUsername: "Kids profile"
    )
    let profileID = "22222222-2222-2222-2222-222222222222"
    let authStub = RootAuthStub(
      tokenUsers: [
        "profile-token": profileUser,
      ]
    )
    let accountProfiles = RootAccountProfileStub(
      profile: AccountProfileItem(
        id: profileID,
        name: "Kids",
        isActive: false,
        isDefault: false,
        lastUsedAt: 20,
        publicUsername: nil,
        avatarURL: nil,
        avatarType: nil,
        avatarCode: nil
      )
    )
    let dependencies = try makeDependencies(
      auth: authStub,
      accountProfiles: accountProfiles
    )
    let coordinator = RootCoordinator(dependencies: dependencies)
    await coordinator.bootstrap()
    try await coordinator.addServer(
      name: "Beta",
      urlInput: "https://beta.example.test"
    )
    try await coordinator.login(
      identifier: "person@example.test",
      password: "secret"
    )
    let serverID = try XCTUnwrap(coordinator.selectedServer?.id)

    try await coordinator.switchAccountProfile(to: profileID)

    XCTAssertEqual(coordinator.state, .authenticated)
    XCTAssertEqual(coordinator.currentUser?.id, "profile-2")
    XCTAssertEqual(
      dependencies.sessionStore.accessToken(forServerID: serverID),
      "profile-token"
    )
    XCTAssertEqual(
      dependencies.sessionStore.session(forServerID: serverID)?
        .accountIdentifier,
      "person@example.test"
    )
  }

  private func makeDependencies(
    probe: ServerProbeServiceProtocol? = nil,
    auth: RootAuthStub? = nil,
    accountProfiles: RootAccountProfileStub? = nil
  ) throws -> AppDependencies {
    let selectedProbe: ServerProbeServiceProtocol
    if let probe {
      selectedProbe = probe
    } else {
      selectedProbe = RootProbeStub(
        metadata: try Self.instanceMetadata()
      )
    }
    let serverStore = ServerStore(defaults: defaults)
    let sessionStore = SessionStore(
      defaults: defaults,
      keychain: RootKeychainStub()
    )
    let apiClient = RootAPIClientStub()
    let settingsService = RootSettingsStub()
    let notificationsService = LiveNotificationsService(
      apiClient: apiClient
    )
    let deArrowService = LiveDeArrowService(
      apiClient: apiClient,
      baseURLProvider: { nil }
    )
    return AppDependencies(
      serverStore: serverStore,
      sessionStore: sessionStore,
      serverProbeService: selectedProbe,
      authService: auth ?? RootAuthStub(),
      oidcService: RootOIDCStub(),
      resetPasswordService: RootResetPasswordStub(),
      homeFeedService: RootHomeFeedStub(),
      commentsService: LiveCommentsService(apiClient: apiClient),
      downloaderService: LiveDownloaderService(apiClient: apiClient),
      deArrowStore: LiveDeArrowStore(
        service: deArrowService,
        settingsService: settingsService
      ),
      searchService: RootSearchStub(),
      searchHistoryService: RootSearchHistoryStub(),
      channelService: RootChannelStub(),
      subscriptionsService: RootSubscriptionsStub(),
      historyService: RootHistoryStub(),
      libraryService: RootLibraryStub(),
      playlistsService: RootPlaylistsStub(),
      profileService: LiveProfileService(apiClient: apiClient),
      accountProfileService: accountProfiles,
      settingsService: settingsService,
      serviceSelection: LiveServiceSelection(
        settingsService: settingsService,
        defaults: defaults
      ),
      notificationsService: notificationsService,
      notificationCenter: LiveNotificationCenter(
        service: notificationsService
      ),
      sessionActivityService: LiveSessionActivityService(
        apiClient: apiClient,
        defaults: defaults
      ),
      adminService: LiveAdminService(apiClient: apiClient),
      adminAccessService: LiveAdminAccessService(apiClient: apiClient),
      contentControlsService: LiveContentControlsService(
        apiClient: apiClient
      ),
      bugReportsService: LiveBugReportsService(apiClient: apiClient),
      importService: LiveImportService(apiClient: apiClient),
      youtubeSessionService: LiveYouTubeSessionService(
        apiClient: apiClient
      )
    )
  }

  private static func instanceMetadata() throws -> InstanceMetadata {
    let data = Data(
      """
      {
        "name": "TypeType",
        "tagline": "Private video",
        "version": "0.1.0-test",
        "apiVersion": 1,
        "registrationAllowed": true,
        "guestAllowed": true,
        "supportedServices": [0, 1],
        "logoUrl": null,
        "bannerUrl": null,
        "localLoginEnabled": true,
        "oidcEnabled": false,
        "oidcProviderName": null,
        "oidcAutoRedirect": false,
        "youtubeRemoteLoginEnabled": false,
        "youtubeRemoteLoginReady": false,
        "youtubeRemoteLoginUnavailableReason": null
      }
      """.utf8
    )
    return try JSONDecoder().decode(InstanceMetadata.self, from: data)
  }
}

private final class RootSettingsStub: LiveSettingsServiceProtocol {
  private var value = LiveSettings()

  func settings() async throws -> LiveSettings {
    value
  }

  func update(_ settings: LiveSettings) async throws -> LiveSettings {
    value = settings
    return value
  }
}

private final class RootProbeStub: ServerProbeServiceProtocol {
  let metadata: InstanceMetadata

  init(metadata: InstanceMetadata) {
    self.metadata = metadata
  }

  func probe(baseURL: URL) async throws -> InstanceMetadata {
    metadata
  }
}

private final class RootOfflineProbeStub:
  ServerProbeServiceProtocol {
  func probe(baseURL: URL) async throws -> InstanceMetadata {
    throw NetworkError.transport
  }
}

private final class RootAuthStub: AuthServiceProtocol {
  private let result = AuthSessionResult(
    user: AuthUser(
      id: "user-1",
      role: .user,
      publicUsername: "person"
    ),
    accountIdentifier: "person@example.test",
    accessToken: "access-1"
  )
  private let tokenUsers: [String: AuthUser]

  init(tokenUsers: [String: AuthUser] = [:]) {
    self.tokenUsers = tokenUsers
  }

  func registrationStatus() async throws -> RegisterStatus {
    RegisterStatus(
      allowRegistration: true,
      bootstrapAvailable: false,
      localLoginEnabled: true
    )
  }

  func login(
    identifier: String,
    password: String
  ) async throws -> AuthSessionResult {
    result
  }

  func register(
    name: String,
    email: String,
    password: String
  ) async throws -> AuthSessionResult {
    result
  }

  func guestLogin() async throws -> AuthSessionResult {
    result
  }

  func refresh() async throws -> String {
    result.accessToken
  }

  func restoreSession(
    snapshot: SessionSnapshot,
    accessToken: String
  ) async throws -> AuthSessionResult {
    result
  }

  func user(accessToken: String) async throws -> AuthUser {
    tokenUsers[accessToken] ?? result.user
  }

  func logout() async throws {}
}

private final class RootAccountProfileStub:
  LiveAccountProfileServiceProtocol {
  private let profile: AccountProfileItem

  init(profile: AccountProfileItem) {
    self.profile = profile
  }

  func list() async throws -> AccountProfilesResponse {
    AccountProfilesResponse(
      profiles: [profile],
      activeProfileID: "11111111-1111-1111-1111-111111111111",
      defaultProfileID: "11111111-1111-1111-1111-111111111111"
    )
  }

  func create(name: String) async throws -> AccountProfileItem {
    profile
  }

  func rename(id: String, name: String) async throws -> AccountProfileItem {
    profile
  }

  func setDefault(id: String) async throws -> AccountProfileItem {
    profile
  }

  func switchTo(id: String) async throws -> ProfileSwitchResponse {
    ProfileSwitchResponse(accessToken: "profile-token", profile: profile)
  }

  func delete(id: String) async throws {}
}

private final class RootOIDCStub: OIDCServiceProtocol {
  func status() async throws -> OIDCStatus {
    OIDCStatus(
      enabled: false,
      providerName: nil,
      localLoginEnabled: true,
      autoRedirect: false
    )
  }

  func start(
    redirectURI: URL,
    returnTo: String?
  ) async throws -> URL {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func complete(
    authorizationCode: OIDCAuthorizationCode,
    redirectURI: URL
  ) async throws -> OIDCCallbackResponse {
    throw RootCoordinatorTestError.unexpectedCall
  }
}

private final class RootResetPasswordStub:
  ResetPasswordServiceProtocol {
  func reset(token: String, newPassword: String) async throws {
    throw RootCoordinatorTestError.unexpectedCall
  }
}

private final class RootHomeFeedStub: HomeFeedServiceProtocol {
  func recommendations(
    serviceID: Int,
    intent: String,
    limit: Int,
    cursor: String?
  ) async throws -> HomeRecommendationsPage {
    HomeRecommendationsPage(
      items: [],
      nextCursor: nil,
      hasMore: false
    )
  }
}

private final class RootSearchStub: LiveSearchServiceProtocol {
  func filters(serviceID: Int) async throws -> LiveSearchFilters {
    LiveSearchFilters(contentFilters: [], sortFilters: [])
  }

  func suggestions(
    query: String,
    serviceID: Int
  ) async throws -> [String] {
    []
  }

  func trending(serviceID: Int) async throws -> [LiveVideoItem] {
    []
  }

  func search(
    query: String,
    serviceID: Int,
    nextPage: String?,
    contentFilter: String?,
    sortFilter: String?
  ) async throws -> LiveSearchPage {
    throw RootCoordinatorTestError.unexpectedCall
  }
}

private final class RootSearchHistoryStub:
  LiveSearchHistoryServiceProtocol {
  func history(
    page: Int,
    limit: Int
  ) async throws -> [LiveSearchHistoryItem] {
    []
  }

  func add(term: String) async throws -> LiveSearchHistoryItem {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func clear() async throws {}
}

private final class RootChannelStub: LiveChannelServiceProtocol {
  func channel(
    url: String,
    nextPage: String?,
    sort: LiveChannelSort
  ) async throws -> LiveChannelPage {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func playlists(
    url: String,
    nextPage: String?
  ) async throws -> LiveChannelPlaylistsPage {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func podcasts(
    url: String,
    nextPage: String?
  ) async throws -> LivePodcastPage {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func podcastEpisodes(
    url: String,
    nextPage: String?
  ) async throws -> LivePodcastEpisodesPage {
    throw RootCoordinatorTestError.unexpectedCall
  }
}

private final class RootSubscriptionsStub:
  LiveSubscriptionsServiceProtocol {
  func subscriptions() async throws -> [LiveSubscription] {
    []
  }

  func feed(
    nextPage: String?
  ) async throws -> LiveSubscriptionFeedPage {
    LiveSubscriptionFeedPage(
      videos: [],
      nextPage: nil,
      generation: nil,
      generatedAt: nil,
      refreshing: false
    )
  }

  func subscribe(
    channelURL: String,
    name: String,
    avatarURL: String
  ) async throws -> LiveSubscription {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func unsubscribe(channelURL: String) async throws {}
}

private final class RootHistoryStub: LiveHistoryServiceProtocol {
  func history(
    query: String?,
    from: Int64?,
    to: Int64?,
    limit: Int,
    offset: Int
  ) async throws -> [LiveHistoryItem] {
    []
  }

  func add(
    video: LiveVideoItem,
    progress: Int64
  ) async throws -> LiveHistoryItem {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func remove(id: String) async throws {}
  func clear() async throws {}
}

private final class RootLibraryStub: LiveLibraryServiceProtocol {
  func favorites() async throws -> [LiveFavoriteItem] { [] }

  func favorite(videoURL: String) async throws -> LiveFavoriteItem? {
    nil
  }

  func addFavorite(videoURL: String) async throws -> LiveFavoriteItem {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func removeFavorite(videoURL: String) async throws {}
  func watchLater() async throws -> [LiveWatchLaterItem] { [] }

  func addWatchLater(
    video: LiveVideoItem
  ) async throws -> LiveWatchLaterItem {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func removeWatchLater(videoURL: String) async throws {}
}

private final class RootPlaylistsStub: LivePlaylistsServiceProtocol {
  func playlists() async throws -> [LivePlaylist] { [] }

  func playlist(id: String) async throws -> LivePlaylist {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func create(
    name: String,
    description: String
  ) async throws -> LivePlaylist {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func update(
    id: String,
    name: String,
    description: String
  ) async throws {}

  func delete(id: String) async throws {}

  func addVideo(
    id: String,
    video: LiveVideoItem
  ) async throws -> LivePlaylistVideo {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func removeVideo(id: String, videoURL: String) async throws {}
  func reorder(id: String, videoURLs: [String]) async throws {}
  func savedPlaylists() async throws -> [LiveSavedPlaylist] { [] }

  func savePublic(url: String) async throws -> LiveSavedPlaylist {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func removeSaved(id: String) async throws {}

  func publicPlaylist(
    url: String,
    nextPage: String?
  ) async throws -> LivePublicPlaylistPage {
    throw RootCoordinatorTestError.unexpectedCall
  }
}

private final class RootKeychainStub: KeychainService {
  private var values: [String: String] = [:]

  func set(_ value: String, for account: String) -> Bool {
    values[account] = value
    return true
  }

  func get(_ account: String) -> String? {
    values[account]
  }

  func remove(_ account: String) -> Bool {
    values.removeValue(forKey: account)
    return true
  }
}

private final class RootAPIClientStub: APIClient {
  func request<T: Decodable>(
    _ endpoint: APIEndpoint,
    as type: T.Type
  ) async throws -> T {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func request(_ endpoint: APIEndpoint) async throws {
    throw RootCoordinatorTestError.unexpectedCall
  }

  func requestData(_ endpoint: APIEndpoint) async throws -> Data {
    throw RootCoordinatorTestError.unexpectedCall
  }
}

private enum RootCoordinatorTestError: Error {
  case unexpectedCall
}
