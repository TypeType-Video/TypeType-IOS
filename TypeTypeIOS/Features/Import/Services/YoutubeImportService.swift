import Foundation

protocol YoutubeImportServiceProtocol {
  func create(archiveURL: URL) async throws -> YoutubeImportJobStatus
  func status(jobID: String) async throws -> YoutubeImportJobStatus
  func preview(jobID: String) async throws -> YoutubeImportPreview
  func commit(jobID: String) async throws -> YoutubeImportJobStatus
  func report(jobID: String) async throws -> YoutubeImportReport
}

private struct YoutubeCommitPayload: Encodable {
  let importSubscriptions: Bool
  let importPlaylists: Bool
  let importPlaylistItems: Bool
}

final class YoutubeImportService: YoutubeImportServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func create(archiveURL: URL) async throws -> YoutubeImportJobStatus {
    let fileName = archiveURL.lastPathComponent.isEmpty ? "takeout.zip" : archiveURL.lastPathComponent
    let formData = try MultipartFormDataBuilder(
      fileURL: archiveURL,
      fieldName: "archive",
      fileName: fileName,
      mimeType: "application/zip"
    ).build()
    let endpoint = APIEndpoint(
      path: "/imports/youtube-takeout",
      method: .post,
      headers: ["Content-Type": formData.contentType],
      body: formData.body,
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: YoutubeImportJobStatus.self)
  }

  func status(jobID: String) async throws -> YoutubeImportJobStatus {
    let endpoint = APIEndpoint(path: "/imports/youtube-takeout/\(encoded(jobID))", method: .get, requiresAuth: true)
    return try await apiClient.request(endpoint, as: YoutubeImportJobStatus.self)
  }

  func preview(jobID: String) async throws -> YoutubeImportPreview {
    let endpoint = APIEndpoint(
      path: "/imports/youtube-takeout/\(encoded(jobID))/preview",
      method: .get,
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: YoutubeImportPreview.self)
  }

  func commit(jobID: String) async throws -> YoutubeImportJobStatus {
    let endpoint = APIEndpoint(
      path: "/imports/youtube-takeout/\(encoded(jobID))/commit",
      method: .post,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(
        YoutubeCommitPayload(importSubscriptions: true, importPlaylists: true, importPlaylistItems: true)
      ),
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: YoutubeImportJobStatus.self)
  }

  func report(jobID: String) async throws -> YoutubeImportReport {
    let endpoint = APIEndpoint(
      path: "/imports/youtube-takeout/\(encoded(jobID))/report",
      method: .get,
      requiresAuth: true
    )
    return try await apiClient.request(endpoint, as: YoutubeImportReport.self)
  }

  private func encoded(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
  }
}
