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
  func keywords() async throws -> [LiveBlockedKeywordItem]
  func addKeyword(_ keyword: String) async throws -> LiveBlockedKeywordItem
  func removeKeyword(_ keyword: String) async throws
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

  func keywords() async throws -> [LiveBlockedKeywordItem] {
    try await apiClient.request(
      endpoint("/blocked/keywords", .get),
      as: [LiveBlockedKeywordItem].self
    )
  }

  func addKeyword(_ keyword: String) async throws -> LiveBlockedKeywordItem {
    struct Request: Encodable { let keyword: String }
    return try await apiClient.request(
      endpoint(
        "/blocked/keywords",
        .post,
        body: try APIEndpoint.jsonBody(Request(keyword: keyword))
      ),
      as: LiveBlockedKeywordItem.self
    )
  }

  func removeKeyword(_ keyword: String) async throws {
    let allowed = CharacterSet.alphanumerics.union(
      CharacterSet(charactersIn: "-._~")
    )
    let encoded = keyword.addingPercentEncoding(
      withAllowedCharacters: allowed
    ) ?? keyword
    try await apiClient.request(
      endpoint("/blocked/keywords/\(encoded)", .delete)
    )
  }

  private func path(for kind: LiveContentControlKind) -> String {
    switch kind {
    case .blockedChannels: return "/blocked/channels"
    case .blockedVideos: return "/blocked/videos"
    case .blockedKeywords, .allowedChannels: return kind == .blockedKeywords
      ? "/blocked/keywords"
      : "/allowed/channels"
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
