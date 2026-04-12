import Foundation

protocol WatchProgressServiceProtocol {
  func progress(for videoURL: String) async throws -> WatchProgress?
  func saveProgress(videoURL: String, position: Int64) async throws
}

private struct ProgressUpdatePayload: Encodable {
  let position: Int64
}

final class WatchProgressService: WatchProgressServiceProtocol {
  private let apiClient: APIClient

  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }

  func progress(for videoURL: String) async throws -> WatchProgress? {
    let endpoint = APIEndpoint(
      path: "/progress/\(pathEncoded(videoURL))",
      method: .get,
      requiresAuth: true
    )
    do {
      return try await apiClient.request(endpoint, as: WatchProgress.self)
    } catch let error as NetworkError {
      guard case .statusCode(404, _) = error else { throw error }
      return nil
    }
  }

  func saveProgress(videoURL: String, position: Int64) async throws {
    let endpoint = APIEndpoint(
      path: "/progress/\(pathEncoded(videoURL))",
      method: .put,
      headers: ["Content-Type": "application/json"],
      body: try APIEndpoint.jsonBody(ProgressUpdatePayload(position: max(0, position))),
      requiresAuth: true
    )
    try await apiClient.request(endpoint)
  }

  private func pathEncoded(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }
}
