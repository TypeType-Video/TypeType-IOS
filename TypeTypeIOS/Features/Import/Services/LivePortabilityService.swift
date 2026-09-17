import Foundation

protocol LivePortabilityServiceProtocol {
  func formats() async throws -> [LivePortabilityFormat]
  func startExport(
    format: String,
    categories: Set<LiveTypeTypeBackupCategory>
  ) async throws -> LivePortabilityJob
  func startImport(
    fileURL: URL,
    fileName: String,
    format: String
  ) async throws -> LivePortabilityJob
  func job(id: String) async throws -> LivePortabilityJob
  func apply(
    id: String,
    categories: Set<LiveTypeTypeBackupCategory>,
    duplicatePolicy: LivePortabilityDuplicatePolicy
  ) async throws -> LivePortabilityJob
  func cancel(id: String) async throws -> LivePortabilityJob
  func delete(id: String) async throws
  func artifact(id: String) async throws -> URL
  func report(id: String) async throws -> URL
}

final class LivePortabilityService: LivePortabilityServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func formats() async throws -> [LivePortabilityFormat] {
    try await apiClient.request(
      endpoint("/portability/formats", .get),
      as: [LivePortabilityFormat].self
    )
  }

  func startExport(
    format: String,
    categories: Set<LiveTypeTypeBackupCategory>
  ) async throws -> LivePortabilityJob {
    try await apiClient.request(
      endpoint(
        "/portability/exports",
        .post,
        body: try APIEndpoint.jsonBody(
          LivePortabilityExportRequest(
            format: format,
            categories: categories.map(\.rawValue).sorted()
          )
        )
      ),
      as: LivePortabilityJob.self
    )
  }

  func startImport(
    fileURL: URL,
    fileName: String,
    format: String
  ) async throws -> LivePortabilityJob {
    let granted = fileURL.startAccessingSecurityScopedResource()
    defer {
      if granted {
        fileURL.stopAccessingSecurityScopedResource()
      }
    }
    let form = try MultipartFormDataBuilder(
      fileURL: fileURL,
      fieldName: "file",
      fileName: fileName,
      mimeType: "application/octet-stream"
    ).build()

    return try await apiClient.request(
      APIEndpoint(
        path: "/portability/imports",
        method: .post,
        queryItems: [URLQueryItem(name: "format", value: format)],
        headers: ["Content-Type": form.contentType],
        body: form.body,
        requiresAuth: true,
        timeoutInterval: 300
      ),
      as: LivePortabilityJob.self
    )
  }

  func job(id: String) async throws -> LivePortabilityJob {
    try await apiClient.request(
      endpoint("/portability/jobs/\(id)", .get),
      as: LivePortabilityJob.self
    )
  }

  func apply(
    id: String,
    categories: Set<LiveTypeTypeBackupCategory>,
    duplicatePolicy: LivePortabilityDuplicatePolicy
  ) async throws -> LivePortabilityJob {
    try await apiClient.request(
      endpoint(
        "/portability/jobs/\(id)/apply",
        .post,
        body: try APIEndpoint.jsonBody(
          LivePortabilityApplyRequest(
            categories: categories.map(\.rawValue).sorted(),
            duplicatePolicy: duplicatePolicy.rawValue
          )
        )
      ),
      as: LivePortabilityJob.self
    )
  }

  func cancel(id: String) async throws -> LivePortabilityJob {
    try await apiClient.request(
      endpoint("/portability/jobs/\(id)/cancel", .post),
      as: LivePortabilityJob.self
    )
  }

  func delete(id: String) async throws {
    try await apiClient.request(
      endpoint("/portability/jobs/\(id)", .delete)
    )
  }

  func artifact(id: String) async throws -> URL {
    try await apiClient.download(
      endpoint("/portability/jobs/\(id)/artifact", .get, timeout: 300)
    )
  }

  func report(id: String) async throws -> URL {
    try await apiClient.download(
      endpoint("/portability/jobs/\(id)/report", .get)
    )
  }

  private func endpoint(
    _ path: String,
    _ method: HTTPMethod,
    body: Data? = nil,
    timeout: TimeInterval? = nil
  ) -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: method,
      body: body,
      requiresAuth: true,
      timeoutInterval: timeout
    )
  }
}
