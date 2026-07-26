import Foundation

protocol LiveContentControlsServiceProtocol {
  func items(
    kind: LiveContentControlKind
  ) async throws -> [LiveContentControlItem]
  func add(
    kind: LiveContentControlKind,
    item: LiveContentControlItem
  ) async throws -> LiveContentControlItem
  func remove(
    kind: LiveContentControlKind,
    url: String
  ) async throws
}

final class LiveContentControlsService:
  LiveContentControlsServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func items(
    kind: LiveContentControlKind
  ) async throws -> [LiveContentControlItem] {
    try await apiClient.request(
      endpoint(path(for: kind), .get),
      as: [LiveContentControlItem].self
    )
  }

  func add(
    kind: LiveContentControlKind,
    item: LiveContentControlItem
  ) async throws -> LiveContentControlItem {
    try await apiClient.request(
      endpoint(
        path(for: kind),
        .post,
        body: try APIEndpoint.jsonBody(item)
      ),
      as: LiveContentControlItem.self
    )
  }

  func remove(
    kind: LiveContentControlKind,
    url: String
  ) async throws {
    try await apiClient.request(
      endpoint("\(path(for: kind))/\(url)", .delete)
    )
  }

  private func path(for kind: LiveContentControlKind) -> String {
    switch kind {
    case .blockedChannels: return "/blocked/channels"
    case .blockedVideos: return "/blocked/videos"
    case .allowedChannels: return "/allowed/channels"
    }
  }

  private func endpoint(
    _ path: String,
    _ method: HTTPMethod,
    body: Data? = nil
  ) -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: method,
      body: body,
      requiresAuth: true
    )
  }
}
