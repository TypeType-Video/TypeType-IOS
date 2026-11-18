import Foundation

protocol LivePresenceServiceProtocol {
  func keys() async throws -> [LivePresenceKey]
  func create(name: String) async throws -> LivePresenceKeyCreated
  func revoke(id: String) async throws
}

struct LivePresenceService: LivePresenceServiceProtocol {
  let apiClient: APIClient

  func keys() async throws -> [LivePresenceKey] {
    try await apiClient.request(APIEndpoint(path: "/presence/keys", method: .get, requiresAuth: true), as: [LivePresenceKey].self)
  }

  func create(name: String) async throws -> LivePresenceKeyCreated {
    let endpoint = APIEndpoint(
      path: "/presence/keys", method: .post, body: try APIEndpoint.jsonBody(["name": name]),
      requiresAuth: true, retriesTransientFailures: false
    )
    return try await apiClient.request(endpoint, as: LivePresenceKeyCreated.self)
  }

  func revoke(id: String) async throws {
    try await apiClient.request(APIEndpoint(path: "/presence/keys/\(id)", method: .delete, requiresAuth: true))
  }
}
