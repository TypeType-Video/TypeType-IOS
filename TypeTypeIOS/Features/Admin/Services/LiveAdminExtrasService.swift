import Foundation

protocol LiveAdminExtrasServiceProtocol {
  func recommenderStatus() async throws -> LiveAdminRecommenderStatus
  func recommenderFeedback() async throws -> LiveAdminRecommenderFeedback
  func rssFeeds(page: Int, limit: Int) async throws -> LiveAdminRssFeedsPage
  func setRssFeed(id: String, enabled: Bool) async throws
  func revokeRssFeed(id: String) async throws
  func setUserRss(id: String, enabled: Bool) async throws
  func announce(_ notice: LiveAdminNoticeRequest) async throws
  func clearNotice() async throws
}

struct LiveAdminExtrasService: LiveAdminExtrasServiceProtocol {
  let apiClient: APIClient

  func recommenderStatus() async throws -> LiveAdminRecommenderStatus {
    let locale = Locale.current.language.languageCode?.identifier ?? "en"
    return try await apiClient.request(
      APIEndpoint(path: "/admin/recommender/status", method: .get, queryItems: [URLQueryItem(name: "locale", value: locale)], requiresAuth: true),
      as: LiveAdminRecommenderStatus.self
    )
  }

  func recommenderFeedback() async throws -> LiveAdminRecommenderFeedback {
    try await apiClient.request(APIEndpoint(path: "/admin/recommender/feedback", method: .get, requiresAuth: true), as: LiveAdminRecommenderFeedback.self)
  }

  func rssFeeds(page: Int, limit: Int) async throws -> LiveAdminRssFeedsPage {
    let query = [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "limit", value: String(limit))]
    return try await apiClient.request(
      APIEndpoint(path: "/admin/rss/feeds", method: .get, queryItems: query, requiresAuth: true), as: LiveAdminRssFeedsPage.self
    )
  }

  func setRssFeed(id: String, enabled: Bool) async throws {
    _ = try await apiClient.requestData(write("/admin/rss/feeds/\(id)/enabled", .put, body: ["enabled": enabled]))
  }

  func revokeRssFeed(id: String) async throws {
    try await apiClient.request(APIEndpoint(path: "/admin/rss/feeds/\(id)", method: .delete, requiresAuth: true))
  }

  func setUserRss(id: String, enabled: Bool) async throws {
    _ = try await apiClient.requestData(write("/admin/rss/users/\(id)/enabled", .put, body: ["enabled": enabled]))
  }

  func announce(_ notice: LiveAdminNoticeRequest) async throws {
    _ = try await apiClient.requestData(write("/admin/server/notice", .post, body: notice))
  }

  func clearNotice() async throws {
    try await apiClient.request(APIEndpoint(path: "/admin/server/notice", method: .delete, requiresAuth: true))
  }

  private func write<Body: Encodable>(_ path: String, _ method: HTTPMethod, body: Body) throws -> APIEndpoint {
    APIEndpoint(path: path, method: method, body: try APIEndpoint.jsonBody(body), requiresAuth: true, retriesTransientFailures: false)
  }
}
