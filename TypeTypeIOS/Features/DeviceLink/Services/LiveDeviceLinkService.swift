import Foundation

protocol LiveDeviceLinkServiceProtocol {
  func lookup(code: String) async throws -> LiveDeviceLinkRequest
  func approve(code: String) async throws
  func deny(code: String) async throws
}

final class LiveDeviceLinkService: LiveDeviceLinkServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func lookup(code: String) async throws -> LiveDeviceLinkRequest {
    try await apiClient.request(
      APIEndpoint(
        path: "/auth/device/lookup",
        method: .get,
        queryItems: [URLQueryItem(name: "code", value: LiveDeviceLinkRequest.normalized(code))],
        requiresAuth: true,
        retriesTransientFailures: false
      ),
      as: LiveDeviceLinkRequest.self
    )
  }

  func approve(code: String) async throws {
    try await decide("/auth/device/approve", code: code)
  }

  func deny(code: String) async throws {
    try await decide("/auth/device/deny", code: code)
  }

  private func decide(_ path: String, code: String) async throws {
    try await apiClient.request(
      APIEndpoint(
        path: path,
        method: .post,
        body: try APIEndpoint.jsonBody(["userCode": LiveDeviceLinkRequest.normalized(code)]),
        requiresAuth: true,
        retriesTransientFailures: false
      )
    )
  }
}
