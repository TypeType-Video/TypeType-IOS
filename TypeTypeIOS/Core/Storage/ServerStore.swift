import Foundation

enum ServerStoreError: LocalizedError {
  case invalidURL
  case duplicateURL

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Enter a valid server URL."
    case .duplicateURL:
      return "This server already exists."
    }
  }
}

final class ServerStore {
  private let defaults: UserDefaults
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func allServers() -> [ServerProfile] {
    guard let data = defaults.data(forKey: AppConfig.serverListKey) else { return [] }
    return (try? decoder.decode([ServerProfile].self, from: data)) ?? []
  }

  func makeServer(name: String, urlInput: String) throws -> ServerProfile {
    guard let normalizedURL = normalizeURL(urlInput) else {
      throw ServerStoreError.invalidURL
    }
    let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return ServerProfile(
      name: displayName.isEmpty ? normalizedURL.host ?? "Server" : displayName,
      baseURLString: normalizedURL.absoluteString
    )
  }

  func insert(_ server: ServerProfile) throws {
    var servers = allServers()
    if servers.contains(where: { $0.baseURLString == server.baseURLString }) {
      throw ServerStoreError.duplicateURL
    }
    servers.append(server)
    saveServers(servers)
    setSelectedServerID(server.id)
  }

  func deleteServer(id: String) {
    let servers = allServers().filter { $0.id != id }
    saveServers(servers)
    if selectedServerID() == id {
      setSelectedServerID(servers.first?.id)
    }
  }

  func selectedServerID() -> String? {
    defaults.string(forKey: AppConfig.selectedServerIDKey)
  }

  func selectedServer() -> ServerProfile? {
    guard let selectedID = selectedServerID() else { return nil }
    return allServers().first(where: { $0.id == selectedID })
  }

  func server(id: String) -> ServerProfile? {
    allServers().first(where: { $0.id == id })
  }

  func replace(_ server: ServerProfile) throws {
    var servers = allServers()
    if servers.contains(where: { $0.id != server.id && $0.baseURLString == server.baseURLString }) {
      throw ServerStoreError.duplicateURL
    }
    guard let index = servers.firstIndex(where: { $0.id == server.id }) else {
      throw ServerStoreError.invalidURL
    }
    servers[index] = server
    saveServers(servers)
    if selectedServerID() == nil {
      setSelectedServerID(server.id)
    }
  }

  func setSelectedServerID(_ id: String?) {
    defaults.set(id, forKey: AppConfig.selectedServerIDKey)
  }

  private func saveServers(_ servers: [ServerProfile]) {
    do {
      defaults.set(try encoder.encode(servers), forKey: AppConfig.serverListKey)
    } catch {
      AppLogger.app.failure("Saving the server list", error)
    }
  }

  private func normalizeURL(_ input: String) -> URL? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
    guard let url = URL(string: withScheme), url.host != nil else { return nil }
    guard var components = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    ) else {
      return nil
    }
    guard ["http", "https"].contains(components.scheme?.lowercased() ?? "") else {
      return nil
    }
    guard components.user == nil, components.password == nil else { return nil }

    if components.path.isEmpty || components.path == "/" {
      components.path = AppConfig.defaultAPIPath
    }
    if components.path.hasSuffix("/") && components.path.count > 1 {
      components.path.removeLast()
    }
    components.query = nil
    components.fragment = nil
    return components.url
  }
}
