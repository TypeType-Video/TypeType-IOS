import Foundation

protocol LiveAccountProfileServiceProtocol {
  func list() async throws -> AccountProfilesResponse
  func create(name: String) async throws -> AccountProfileItem
  func rename(id: String, name: String) async throws -> AccountProfileItem
  func setDefault(id: String) async throws -> AccountProfileItem
  func switchTo(id: String) async throws -> ProfileSwitchResponse
  func delete(id: String) async throws
}

final class LiveAccountProfileService: LiveAccountProfileServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func list() async throws -> AccountProfilesResponse {
    try await apiClient.request(
      APIEndpoint(path: "/profiles", method: .get),
      as: AccountProfilesResponse.self
    )
  }

  func create(name: String) async throws -> AccountProfileItem {
    try await apiClient.request(
      APIEndpoint(
        path: "/profiles",
        method: .post,
        body: try APIEndpoint.jsonBody(ProfileNamePayload(name: name))
      ),
      as: AccountProfileItem.self
    )
  }

  func rename(id: String, name: String) async throws -> AccountProfileItem {
    try await apiClient.request(
      APIEndpoint(
        path: "/profiles/\(id)",
        method: .put,
        body: try APIEndpoint.jsonBody(ProfileNamePayload(name: name))
      ),
      as: AccountProfileItem.self
    )
  }

  func setDefault(id: String) async throws -> AccountProfileItem {
    try await apiClient.request(
      APIEndpoint(path: "/profiles/\(id)/default", method: .post),
      as: AccountProfileItem.self
    )
  }

  func switchTo(id: String) async throws -> ProfileSwitchResponse {
    try await apiClient.request(
      APIEndpoint(path: "/profiles/\(id)/switch", method: .post),
      as: ProfileSwitchResponse.self
    )
  }

  func delete(id: String) async throws {
    try await apiClient.request(
      APIEndpoint(path: "/profiles/\(id)", method: .delete)
    )
  }
}
