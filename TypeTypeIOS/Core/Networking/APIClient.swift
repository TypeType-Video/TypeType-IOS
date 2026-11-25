import Foundation

protocol APIClient {
  func request<T: Decodable>(
    _ endpoint: APIEndpoint,
    as type: T.Type
  ) async throws -> T
  func request(_ endpoint: APIEndpoint) async throws
  func requestData(_ endpoint: APIEndpoint) async throws -> Data
  func upload<T: Decodable>(
    _ endpoint: APIEndpoint,
    from fileURL: URL,
    as type: T.Type
  ) async throws -> T
  func download(_ endpoint: APIEndpoint) async throws -> URL
  func download(
    _ endpoint: APIEndpoint,
    resumeData: Data?,
    progress: @escaping @Sendable (DownloadProgress) -> Void
  ) async throws -> URL
}

// A transfer cut short with enough state to continue it: handing `resumeData` back resumes where it stopped.
struct DownloadInterruption: Error {
  let resumeData: Data
}

extension APIClient {
  func upload<T: Decodable>(
    _ endpoint: APIEndpoint,
    from fileURL: URL,
    as type: T.Type
  ) async throws -> T {
    let body = try Data(contentsOf: fileURL)
    return try await request(
      APIEndpoint(
        path: endpoint.path,
        method: endpoint.method,
        queryItems: endpoint.queryItems,
        headers: endpoint.headers,
        body: body,
        requiresAuth: endpoint.requiresAuth,
        timeoutInterval: endpoint.timeoutInterval
      ),
      as: type
    )
  }

  func download(
    _ endpoint: APIEndpoint,
    resumeData: Data?,
    progress: @escaping @Sendable (DownloadProgress) -> Void
  ) async throws -> URL {
    try await download(endpoint)
  }

  func download(_ endpoint: APIEndpoint) async throws -> URL {
    let data = try await requestData(endpoint)
    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try data.write(to: fileURL, options: .atomic)
    return fileURL
  }
}
