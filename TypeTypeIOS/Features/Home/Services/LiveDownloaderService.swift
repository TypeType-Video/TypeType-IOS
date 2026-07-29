import Foundation

protocol LiveDownloaderServiceProtocol {
  func create(
    videoURL: String,
    options: LiveDownloadOptions
  ) async throws -> LiveDownloadJob
  func job(id: String) async throws -> LiveDownloadJob
  func cancel(id: String) async throws -> LiveDownloadJob
  func delete(id: String) async throws
  func artifact(id: String) async throws -> URL
}

final class LiveDownloaderService: LiveDownloaderServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func create(
    videoURL: String,
    options: LiveDownloadOptions
  ) async throws -> LiveDownloadJob {
    let creation = try await apiClient.request(
      APIEndpoint(
        path: "/downloader/jobs",
        method: .post,
        body: try APIEndpoint.jsonBody(
          LiveDownloadRequest(url: videoURL, options: options)
        ),
        requiresAuth: true,
        timeoutInterval: 90
      ),
      as: LiveDownloadCreationResponse.self
    )
    return try await job(id: creation.id)
  }

  func job(id: String) async throws -> LiveDownloadJob {
    try await apiClient.request(
      endpoint("/downloader/jobs/\(id)", .get),
      as: LiveDownloadJob.self
    )
  }

  func cancel(id: String) async throws -> LiveDownloadJob {
    try await apiClient.request(
      endpoint("/downloader/jobs/\(id)/cancel", .post),
      as: LiveDownloadJob.self
    )
  }

  func delete(id: String) async throws {
    do {
      try await apiClient.request(
        endpoint("/downloader/jobs/\(id)", .delete)
      )
    } catch let error as NetworkError {
      guard case .statusCode(404, _) = error else { throw error }
    }
  }

  func artifact(id: String) async throws -> URL {
    try await apiClient.download(
      endpoint("/downloader/jobs/\(id)/artifact", .get)
    )
  }

  private func endpoint(
    _ path: String,
    _ method: HTTPMethod
  ) -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: method,
      requiresAuth: true,
      timeoutInterval: 90
    )
  }
}

private struct LiveDownloadCreationResponse: Decodable {
  let id: String
}
