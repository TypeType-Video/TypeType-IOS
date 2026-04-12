import Foundation

protocol ChannelServiceProtocol {
  func channel(url: String, nextPage: String?) async throws -> ChannelPage
}

final class ChannelService: ChannelServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func channel(url: String, nextPage: String? = nil) async throws -> ChannelPage {
    var query = [URLQueryItem(name: "url", value: url)]
    if let nextPage, !nextPage.isEmpty {
      query.append(URLQueryItem(name: "nextpage", value: nextPage))
    }
    let endpoint = APIEndpoint(path: "/channel", method: .get, queryItems: query)
    return try await apiClient.request(endpoint, as: ChannelPage.self)
  }
}
