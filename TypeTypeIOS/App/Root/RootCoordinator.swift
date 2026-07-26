import Combine
import Foundation

@MainActor
final class RootCoordinator: ObservableObject {
  @Published private(set) var state = RootState.booting
  @Published private(set) var servers: [ServerProfile] = []
  @Published private(set) var selectedServer: ServerProfile?
  @Published private(set) var instance: InstanceMetadata?
  @Published private(set) var currentUser: AuthUser?
  @Published var connectionError: String?

  let dependencies: AppDependencies
  private var didBootstrap = false

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
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
    dependencies.serviceSelection.configure(
      supportedServiceIDs: metadata.supportedServices
    )
    connectionError = nil
    state = .authentication
  }

  func selectServer(_ server: ServerProfile) async {
    await activate(server, restoresSession: true)
  }

  func deleteServer(_ server: ServerProfile) {
    let wasSelected = selectedServer?.id == server.id
    dependencies.sessionStore.clearSession(forServerID: server.id)
    dependencies.serverStore.deleteServer(id: server.id)
    reloadServers()
    if wasSelected {
      instance = nil
      currentUser = nil
    }
    state = .serverSetup
  }

  func showServerSetup() {
    state = .serverSetup
  }

  func login(identifier: String, password: String) async throws {
    let result = try await dependencies.authService.login(
      identifier: identifier,
      password: password
    )
    completeAuthentication(result)
  }

  func register(
    name: String,
    email: String,
    password: String
  ) async throws {
    let result = try await dependencies.authService.register(
      name: name,
      email: email,
      password: password
    )
    completeAuthentication(result)
  }

  func continueAsGuest() async throws {
    completeAuthentication(
      try await dependencies.authService.guestLogin()
    )
  }

  func continueWithOIDC() async throws {
    let coordinator = OIDCAuthenticationCoordinator(
      oidcService: dependencies.oidcService,
      authService: dependencies.authService
    )
    completeAuthentication(try await coordinator.signIn())
  }

  func signOut() async {
    try? await dependencies.authService.logout()
    dependencies.notificationCenter.clear()
    if let serverID = selectedServer?.id {
      dependencies.sessionStore.clearSession(forServerID: serverID)
    }
    currentUser = nil
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

  private func activate(
    _ server: ServerProfile,
    restoresSession: Bool
  ) async {
    state = .booting
    connectionError = nil
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
    } catch {
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
      dependencies.sessionStore.clearSession(forServerID: server.id)
      currentUser = nil
      state = .authentication
    }
  }

  private func completeAuthentication(_ result: AuthSessionResult) {
    guard let server = selectedServer else { return }
    let snapshot = SessionSnapshot(
      serverID: server.id,
      userID: result.user.id,
      accountIdentifier: result.accountIdentifier,
      role: result.user.role.rawValue
    )
    dependencies.sessionStore.saveSession(
      snapshot: snapshot,
      accessToken: result.accessToken
    )
    currentUser = result.user
    state = .authenticated
    Task {
      await dependencies.serviceSelection.refresh()
    }
  }

  private func reloadServers() {
    servers = dependencies.serverStore.allServers()
      .sorted { $0.createdAt < $1.createdAt }
    selectedServer =
      dependencies.serverStore.selectedServer() ?? servers.first
    if let selectedServer {
      dependencies.serverStore.setSelectedServerID(selectedServer.id)
    }
  }
}
