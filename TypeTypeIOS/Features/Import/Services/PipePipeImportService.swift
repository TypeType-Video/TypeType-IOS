import Foundation

protocol PipePipeImportServiceProtocol {
  func restore(archiveURL: URL, timeMode: String) async throws -> PipePipeRestoreSummary
}

final class PipePipeImportService: PipePipeImportServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func restore(archiveURL: URL, timeMode: String = "normalized") async throws -> PipePipeRestoreSummary {
    let fieldName = "file"
    let fileName = archiveURL.lastPathComponent.isEmpty ? "backup.zip" : archiveURL.lastPathComponent
    let formData = try MultipartFormDataBuilder(
      fileURL: archiveURL,
      fieldName: fieldName,
      fileName: fileName,
      mimeType: "application/zip"
    ).build()
    let endpoint = APIEndpoint(
      path: "/restore/pipepipe",
      method: .post,
      queryItems: [URLQueryItem(name: "timeMode", value: timeMode)],
      headers: ["Content-Type": formData.contentType],
      body: formData.body,
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: PipePipeRestoreSummary.self)
  }
}
