import Combine
import Foundation

@MainActor
final class RootCoordinator: ObservableObject {
  @Published var state: RootState = .booting
  @Published var servers: [ServerProfile] = []
  @Published var selectedServer: ServerProfile?
  @Published var currentSession: SessionSnapshot?

  let dependencies: AppDependencies

  init(dependencies: AppDependencies) {
    self.dependencies = dependencies
    bootstrap()
  }

  func bootstrap() {
    let store = dependencies.serverStore
    servers = store.allServers().sorted(by: { $0.createdAt < $1.createdAt })
    selectedServer = store.selectedServer() ?? servers.first
    if let selectedServer {
      store.setSelectedServerID(selectedServer.id)
    }
    if let selectedID = selectedServer?.id {
      currentSession = dependencies.sessionStore.session(forServerID: selectedID)
    } else {
      currentSession = nil
    }
    updateStateForCurrentContext()
  }

  func addServer(name: String, urlInput: String) async throws {
    let server = try dependencies.serverStore.makeServer(name: name, urlInput: urlInput)
    guard let baseURL = server.baseURL else {
      throw ServerStoreError.invalidURL
    }
    try await dependencies.serverProbeService.probe(baseURL: baseURL)
    try dependencies.serverStore.insert(server)
    bootstrap()
    setSelectedServer(server)
  }

  func deleteServer(_ server: ServerProfile) {
    dependencies.serverStore.deleteServer(id: server.id)
    dependencies.sessionStore.clearSession(forServerID: server.id)
    bootstrap()
  }

  func updateServer(id: String, name: String, urlInput: String) async throws {
    guard let existing = dependencies.serverStore.server(id: id) else {
      throw ServerStoreError.invalidURL
    }
    let draft = try dependencies.serverStore.makeServer(name: name, urlInput: urlInput)
    guard let baseURL = draft.baseURL else {
      throw ServerStoreError.invalidURL
    }
    try await dependencies.serverProbeService.probe(baseURL: baseURL)
    let updated = ServerProfile(
      id: existing.id,
      name: draft.name,
      baseURLString: draft.baseURLString,
      createdAt: existing.createdAt
    )
    try dependencies.serverStore.replace(updated)
    bootstrap()
  }

  func setSelectedServer(_ server: ServerProfile) {
    selectedServer = server
    dependencies.serverStore.setSelectedServerID(server.id)
    updateStateForCurrentContext()
  }

  func completeAuthentication(_ result: AuthSessionResult) {
    guard let selectedServer else { return }
    let snapshot = SessionSnapshot(
      serverID: selectedServer.id,
      userID: result.userID,
      userEmail: result.email,
      role: result.role.rawValue
    )
    dependencies.sessionStore.saveSession(snapshot: snapshot, accessToken: result.token)
    currentSession = snapshot
    state = .main
  }

  func signOut() {
    if let serverID = selectedServer?.id {
      dependencies.sessionStore.clearSession(forServerID: serverID)
    }
    currentSession = nil
    state = selectedServer == nil ? .serverSetup : .auth
  }

  private func updateStateForCurrentContext() {
    guard let selectedServer else {
      state = .serverSetup
      return
    }
    if dependencies.sessionStore.hasActiveSession(serverID: selectedServer.id) {
      currentSession = dependencies.sessionStore.session(forServerID: selectedServer.id)
      state = .main
    } else {
      currentSession = nil
      state = .auth
    }
  }
}
