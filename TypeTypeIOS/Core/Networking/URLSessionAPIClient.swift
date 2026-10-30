import Foundation

final class URLSessionAPIClient: APIClient {
  typealias TokenRefreshHandler = (String) async throws -> String?

  let serverURLProvider: () -> URL?
  let accessTokenProvider: () -> String?
  let session: URLSession
  let mediaSession: URLSession
  let mediaTaskPriority = MediaTaskPriority()
  let downloadSession: URLSession
  let decoder: JSONDecoder
  let diagnosticsStore: LiveDiagnosticsStore?
  let diagnosticScopeProvider: () -> LiveDiagnosticScope?
  let tokenRefreshGate = TokenRefreshGate()
  var tokenRefreshHandler: TokenRefreshHandler?
  var refreshCookieObserver: ((String?) -> Void)?

  init(
    serverURLProvider: @escaping () -> URL?,
    accessTokenProvider: @escaping () -> String?,
    session: URLSession = URLSessionAPIClient.makeSession(),
    mediaSession: URLSession = URLSessionAPIClient.makeMediaSession(),
    decoder: JSONDecoder = JSONDecoder(),
    diagnosticsStore: LiveDiagnosticsStore? = nil,
    diagnosticScopeProvider: @escaping () -> LiveDiagnosticScope? = {
      nil
    }
  ) {
    self.serverURLProvider = serverURLProvider
    self.accessTokenProvider = accessTokenProvider
    self.session = session
    self.mediaSession = mediaSession
    self.downloadSession = Self.makeDownloadSession(like: session)
    self.decoder = decoder
    self.diagnosticsStore = diagnosticsStore
    self.diagnosticScopeProvider = diagnosticScopeProvider
  }

  func setTokenRefreshHandler(_ handler: @escaping TokenRefreshHandler) {
    tokenRefreshHandler = handler
  }

  func setRefreshCookieObserver(_ observer: @escaping (String?) -> Void) {
    refreshCookieObserver = observer
  }

  func request<T: Decodable>(
    _ endpoint: APIEndpoint,
    as type: T.Type
  ) async throws -> T {
    let data = try await requestData(endpoint)
    do {
      return try decoder.decode(type, from: data)
    } catch {
      AppLogger.network.error(
        "Decode failure for \(endpoint.path, privacy: .public)"
      )
      throw NetworkError.decoding
    }
  }

  func request(_ endpoint: APIEndpoint) async throws {
    _ = try await requestData(endpoint)
  }

  func upload<T: Decodable>(
    _ endpoint: APIEndpoint,
    from fileURL: URL,
    as type: T.Type
  ) async throws -> T {
    let data = try await uploadData(endpoint, from: fileURL)
    do {
      return try decoder.decode(type, from: data)
    } catch {
      AppLogger.network.error(
        "Decode failure for \(endpoint.path, privacy: .public)"
      )
      throw NetworkError.decoding
    }
  }

  func requestData(_ endpoint: APIEndpoint) async throws -> Data {
    let request = try makeURLRequest(endpoint)
    let retries = endpoint.retriesTransientFailures
    let media = endpoint.isMedia
    do {
      return try await executeRead(request, retries: retries) {
        try await self.execute(request, media: media)
      }
    } catch let error as NetworkError {
      guard case .statusCode(401, _) = error else { throw error }
      guard endpoint.requiresAuth else { throw error }
      guard let retryRequest = await makeRetryRequest(from: request) else {
        throw error
      }
      return try await executeRead(retryRequest, retries: retries) {
        try await self.execute(retryRequest, media: media)
      }
    }
  }

  func download(_ endpoint: APIEndpoint) async throws -> URL {
    let request = try makeURLRequest(endpoint)
    do {
      return try await executeRead(request) {
        try await self.executeDownload(request)
      }
    } catch let error as NetworkError {
      guard case .statusCode(401, _) = error else { throw error }
      guard endpoint.requiresAuth else { throw error }
      guard let retryRequest = await makeRetryRequest(from: request) else {
        throw error
      }
      return try await executeRead(retryRequest) {
        try await self.executeDownload(retryRequest)
      }
    }
  }

  private func uploadData(
    _ endpoint: APIEndpoint,
    from fileURL: URL
  ) async throws -> Data {
    var request = try makeURLRequest(endpoint)
    request.httpBody = nil
    do {
      return try await executeUpload(request, from: fileURL)
    } catch let error as NetworkError {
      guard case .statusCode(401, _) = error else { throw error }
      guard endpoint.requiresAuth else { throw error }
      guard let retryRequest = await makeRetryRequest(from: request) else {
        throw error
      }
      return try await executeUpload(retryRequest, from: fileURL)
    }
  }
}
