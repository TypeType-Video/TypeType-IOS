import Foundation

protocol LiveImportServiceProtocol {
  func restorePipePipe(
    data: Data,
    fileName: String,
    timeMode: String
  ) async throws -> LivePipePipeRestoreResult
  func createYouTubeImport(
    data: Data,
    fileName: String
  ) async throws -> LiveYouTubeImportJob
  func youTubeJob(id: String) async throws -> LiveYouTubeImportJob
  func youTubePreview(id: String) async throws -> LiveYouTubeImportPreview
  func commitYouTube(
    id: String,
    options: LiveYouTubeImportCommit
  ) async throws -> LiveYouTubeImportJob
  func youTubeReport(id: String) async throws -> LiveYouTubeImportReport
}

final class LiveImportService: LiveImportServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func restorePipePipe(
    data: Data,
    fileName: String,
    timeMode: String
  ) async throws -> LivePipePipeRestoreResult {
    let form = MultipartFormData(
      fieldName: "file",
      fileName: fileName,
      mediaType: "application/zip",
      data: data
    )
    return try await apiClient.request(
      uploadEndpoint(
        "/restore/pipepipe",
        form: form,
        query: [URLQueryItem(name: "timeMode", value: timeMode)]
      ),
      as: LivePipePipeRestoreResult.self
    )
  }

  func createYouTubeImport(
    data: Data,
    fileName: String
  ) async throws -> LiveYouTubeImportJob {
    let form = MultipartFormData(
      fieldName: "archive",
      fileName: fileName,
      mediaType: "application/zip",
      data: data
    )
    return try await apiClient.request(
      uploadEndpoint("/imports/youtube-takeout", form: form),
      as: LiveYouTubeImportJob.self
    )
  }

  func youTubeJob(id: String) async throws -> LiveYouTubeImportJob {
    try await apiClient.request(
      endpoint("/imports/youtube-takeout/\(id)", .get),
      as: LiveYouTubeImportJob.self
    )
  }

  func youTubePreview(
    id: String
  ) async throws -> LiveYouTubeImportPreview {
    try await apiClient.request(
      endpoint("/imports/youtube-takeout/\(id)/preview", .get),
      as: LiveYouTubeImportPreview.self
    )
  }

  func commitYouTube(
    id: String,
    options: LiveYouTubeImportCommit
  ) async throws -> LiveYouTubeImportJob {
    try await apiClient.request(
      endpoint(
        "/imports/youtube-takeout/\(id)/commit",
        .post,
        body: try APIEndpoint.jsonBody(options)
      ),
      as: LiveYouTubeImportJob.self
    )
  }

  func youTubeReport(
    id: String
  ) async throws -> LiveYouTubeImportReport {
    try await apiClient.request(
      endpoint("/imports/youtube-takeout/\(id)/report", .get),
      as: LiveYouTubeImportReport.self
    )
  }

  private func uploadEndpoint(
    _ path: String,
    form: MultipartFormData,
    query: [URLQueryItem] = []
  ) -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: .post,
      queryItems: query,
      headers: ["Content-Type": form.contentType],
      body: form.body,
      requiresAuth: true,
      timeoutInterval: 120
    )
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
      requiresAuth: true,
      timeoutInterval: 90
    )
  }
}
