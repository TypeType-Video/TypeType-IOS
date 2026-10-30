import Foundation

struct LiveComponentVersion: Codable, Equatable {
  let service: String
  let version: String
  let revision: String
  let shortRevision: String
  let buildTime: String
}

struct LiveComponentVersions: Codable, Equatable {
  let frontend: LiveComponentVersion?
  let server: LiveComponentVersion?
  let token: LiveComponentVersion?
  let downloader: LiveComponentVersion?
}

protocol LiveVersionServiceProtocol {
  func fetchVersions() async throws -> LiveComponentVersions
}

final class LiveVersionService: LiveVersionServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func fetchVersions() async throws -> LiveComponentVersions {
    async let frontend = version("web")
    async let server = version("server")
    async let token = version("token")
    async let downloader = version("downloader")

    return LiveComponentVersions(
      frontend: try? await frontend,
      server: try? await server,
      token: try? await token,
      downloader: try? await downloader
    )
  }

  private func version(_ component: String) async throws -> LiveComponentVersion {
    try await apiClient.request(
      APIEndpoint(
        path: "/version/\(component)",
        method: .get,
        requiresAuth: true
      ),
      as: LiveComponentVersion.self
    )
  }
}
