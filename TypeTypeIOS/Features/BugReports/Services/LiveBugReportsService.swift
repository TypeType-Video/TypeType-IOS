import Foundation

protocol LiveBugReportsServiceProtocol {
  func create(
    category: String,
    description: String,
    videoURL: String?
  ) async throws -> LiveCreatedBugReport
  func reports(
    page: Int,
    limit: Int,
    status: String?,
    category: String?
  ) async throws -> LiveAdminBugReportsPage
  func detail(id: String) async throws -> LiveAdminBugReportDetail
  func updateStatus(id: String, status: String) async throws
  func createGitHubIssue(id: String) async throws -> URL
}

final class LiveBugReportsService: LiveBugReportsServiceProtocol {
  private let apiClient: APIClient
  private let diagnosticsStore: LiveDiagnosticsStore?
  private let diagnosticScopeProvider: () -> LiveDiagnosticScope?

  init(
    apiClient: APIClient,
    diagnosticsStore: LiveDiagnosticsStore? = nil,
    diagnosticScopeProvider: @escaping () -> LiveDiagnosticScope? = {
      nil
    }
  ) {
    self.apiClient = apiClient
    self.diagnosticsStore = diagnosticsStore
    self.diagnosticScopeProvider = diagnosticScopeProvider
  }

  func create(
    category: String,
    description: String,
    videoURL: String?
  ) async throws -> LiveCreatedBugReport {
    let diagnostics: [LiveDiagnosticEntry]
    if let diagnosticsStore,
      let scope = diagnosticScopeProvider() {
      diagnostics = await diagnosticsStore.entries(for: scope)
    } else {
      diagnostics = []
    }
    let context = LiveBugReportContextPayload(
      videoURL: videoURL,
      route: "ios://report",
      timestamp: Int64(Date().timeIntervalSince1970 * 1_000),
      userAgent: "TypeType iOS",
      browserLanguage: Locale.current.identifier,
      crashLogs: [],
      apiErrors: diagnostics.compactMap { entry in
        guard let status = entry.statusCode, status >= 400 else {
          return nil
        }
        return LiveBugAPIError(
          requestID: entry.requestID,
          endpoint: entry.route,
          status: status,
          code: nil,
          message: nil,
          timestamp: Int64(
            entry.timestamp.timeIntervalSince1970 * 1_000
          )
        )
      }
      .prefix(100)
      .map { $0 }
    )
    return try await apiClient.request(
      endpoint(
        "/bug-reports",
        .post,
        body: try APIEndpoint.jsonBody(
          LiveCreateBugReportPayload(
            category: category,
            description: description,
            context: context
          )
        )
      ),
      as: LiveCreatedBugReport.self
    )
  }

  func reports(
    page: Int,
    limit: Int,
    status: String?,
    category: String?
  ) async throws -> LiveAdminBugReportsPage {
    var query = [
      URLQueryItem(name: "page", value: String(page)),
      URLQueryItem(name: "limit", value: String(limit)),
    ]
    status.map { query.append(URLQueryItem(name: "status", value: $0)) }
    category.map {
      query.append(URLQueryItem(name: "category", value: $0))
    }
    return try await apiClient.request(
      APIEndpoint(
        path: "/admin/bug-reports",
        method: .get,
        queryItems: query,
        requiresAuth: true
      ),
      as: LiveAdminBugReportsPage.self
    )
  }

  func detail(id: String) async throws -> LiveAdminBugReportDetail {
    try await apiClient.request(
      endpoint("/admin/bug-reports/\(id)", .get),
      as: LiveAdminBugReportDetail.self
    )
  }

  func updateStatus(id: String, status: String) async throws {
    _ = try await apiClient.request(
      endpoint(
        "/admin/bug-reports/\(id)/status",
        .put,
        body: try APIEndpoint.jsonBody(
          LiveBugReportStatusPayload(status: status)
        )
      ),
      as: LiveBugReportStatusResult.self
    )
  }

  func createGitHubIssue(id: String) async throws -> URL {
    let result = try await apiClient.request(
      endpoint("/admin/bug-reports/\(id)/github-issue", .post),
      as: LiveBugReportGitHubResult.self
    )
    return result.githubIssueURL
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
