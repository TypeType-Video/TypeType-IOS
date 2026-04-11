import Foundation

protocol SearchServiceProtocol {
  func search(query: String, serviceID: Int, nextPage: String?) async throws -> SearchPageResult
}

final class SearchService: SearchServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func search(query: String, serviceID: Int, nextPage: String?) async throws -> SearchPageResult {
    var params = [
      URLQueryItem(name: "q", value: query),
      URLQueryItem(name: "service", value: "\(serviceID)"),
    ]
    if let nextPage, !nextPage.isEmpty {
      params.append(URLQueryItem(name: "nextpage", value: nextPage))
    }
    let endpoint = APIEndpoint(path: "/search", method: .get, queryItems: params)
    return try await apiClient.request(endpoint, as: SearchPageResult.self)
  }
}
