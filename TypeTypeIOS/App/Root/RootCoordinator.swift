import Combine
import Foundation

@MainActor
final class RootCoordinator: ObservableObject {
  @Published var state = RootState.booting
  @Published var servers: [ServerProfile] = []
  @Published var selectedServer: ServerProfile?
  @Published var instance: InstanceMetadata?
  @Published var currentUser: AuthUser?
  @Published var selectedTab: LiveAuthenticatedTab = .home
  @Published var searchTabRetaps = 0

  func handleTabReselection(_ tab: LiveAuthenticatedTab) {
    if tab == .search {
      searchTabRetaps += 1
    }
  }
  @Published var pendingIncomingURL: URL?
  @Published var isUsingOfflineSession = false
  @Published var connectionError: String?

  var identityScopeID: String {
    [
      selectedServer?.id ?? "no-server",
      currentUser?.id ?? "no-user",
    ].joined(separator: ":")
  }

  let dependencies: AppDependencies
  private var didBootstrap = false
  private var sessionExpiryObservation: AnyCancellable?

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
    sessionExpiryObservation = NotificationCenter.default
      .publisher(for: .liveSessionExpired)
      .compactMap { $0.userInfo?[LiveSessionExpiry.serverIDKey] as? String }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] serverID in
        self?.sessionDidExpire(serverID: serverID)
      }
  }

  func bootstrap() async {
    guard !didBootstrap else { return }
    didBootstrap = true
    reloadServers()
    guard let server = selectedServer else {
      state = .serverSetup
      return
    }
    await activate(server, restoresSession: true)
  }

  func addServer(name: String, urlInput: String) async throws {
    let server = try dependencies.serverStore.makeServer(
      name: name,
      urlInput: urlInput
    )
    guard let baseURL = server.baseURL else {
      throw ServerStoreError.invalidURL
    }
    let metadata = try await dependencies.serverProbeService.probe(
      baseURL: baseURL
    )
    try dependencies.serverStore.insert(server)
    reloadServers()
    selectedServer = server
    instance = metadata
    isUsingOfflineSession = false
    dependencies.serviceSelection.configure(
      supportedServiceIDs: metadata.supportedServices
    )
    dependencies.pushNotificationsEnabled =
      metadata.pushNotifications?.enabled == true
    dependencies.rssEnabled = metadata.rss?.enabled == true
    connectionError = nil
    state = .authentication
  }

  func selectServer(_ server: ServerProfile) async {
    await activate(server, restoresSession: true)
  }

  func deleteServer(_ server: ServerProfile) {
    let wasSelected = selectedServer?.id == server.id
    dependencies.playbackCoordinator.forgetServer(server.id)
    dependencies.sessionStore.clearSession(forServerID: server.id)
    dependencies.serverStore.deleteServer(id: server.id)
    reloadServers()
    if wasSelected {
      instance = nil
      currentUser = nil
      isUsingOfflineSession = false
      dependencies.invalidateIdentityScopedRuntimeState()
    }
    state = .serverSetup
  }

  func showServerSetup() {
    dependencies.playbackCoordinator.endSession()
    state = .serverSetup
  }

  func signOut() async {
    do {
      try await dependencies.authService.logout()
    } catch {
      AppLogger.auth.failure("Signing out on the server", error)
    }
    if let serverID = selectedServer?.id, let userID = currentUser?.id {
      dependencies.sessionStore.savedAccounts.forget(serverID: serverID, userID: userID)
    }
    endSession()
  }

  private func sessionDidExpire(serverID: String) {
    guard serverID == selectedServer?.id, state == .authenticated, !isUsingOfflineSession else { return }
    endSession()
  }

  private func endSession() {
    dependencies.invalidateIdentityScopedRuntimeState()
    if let serverID = selectedServer?.id {
      dependencies.sessionStore.clearSession(forServerID: serverID)
    }
    currentUser = nil
    isUsingOfflineSession = false
    state = selectedServer == nil ? .serverSetup : .authentication
  }

  func refreshCurrentUser() async {
    guard let serverID = selectedServer?.id,
      let token = dependencies.sessionStore.accessToken(
        forServerID: serverID
      )
    else {
      return
    }
    do {
      currentUser = try await dependencies.authService.user(
        accessToken: token
      )
    } catch {
      connectionError = error.localizedDescription
    }
  }

  func reloadServers() {
    servers = dependencies.serverStore.allServers()
      .sorted { $0.createdAt < $1.createdAt }
    selectedServer =
      dependencies.serverStore.selectedServer() ?? servers.first
    if let selectedServer {
      dependencies.serverStore.setSelectedServerID(selectedServer.id)
    }
  }
}
