import Foundation

final class URLSessionAPIClient: APIClient {
  typealias TokenRefreshHandler = (String) async throws -> String?

  private let serverURLProvider: () -> URL?
  private let accessTokenProvider: () -> String?
  private let session: URLSession
  private let decoder = JSONDecoder()
  private let tokenRefreshGate = TokenRefreshGate()
  private var tokenRefreshHandler: TokenRefreshHandler?

  init(
    serverURLProvider: @escaping () -> URL?,
    accessTokenProvider: @escaping () -> String?,
    session: URLSession = .shared
  ) {
    self.serverURLProvider = serverURLProvider
    self.accessTokenProvider = accessTokenProvider
    self.session = session
  }

  func setTokenRefreshHandler(_ handler: @escaping TokenRefreshHandler) {
    tokenRefreshHandler = handler
  }

  func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
    let data = try await send(endpoint)
    do {
      return try decoder.decode(type, from: data)
    } catch {
      throw NetworkError.decoding
    }
  }

  func request(_ endpoint: APIEndpoint) async throws {
    _ = try await send(endpoint)
  }

  private func send(_ endpoint: APIEndpoint) async throws -> Data {
    let request = try makeURLRequest(endpoint)
    do {
      return try await execute(request)
    } catch let error as NetworkError {
      guard case .statusCode(401, _) = error else { throw error }
      guard endpoint.requiresAuth else { throw error }
      guard let retryRequest = await makeRetryRequest(from: request) else { throw error }
      return try await execute(retryRequest)
    }
  }

  private func execute(_ request: URLRequest) async throws -> Data {
    do {
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
      }
      guard (200...299).contains(http.statusCode) else {
        throw NetworkError.statusCode(http.statusCode, errorMessage(from: data))
      }
      return data
    } catch let error as NetworkError {
      throw error
    } catch {
      throw NetworkError.transport
    }
  }

  private func makeRetryRequest(from request: URLRequest) async -> URLRequest? {
    guard let tokenRefreshHandler else { return nil }
    guard let staleToken = bearerToken(from: request) ?? accessTokenProvider() else { return nil }
    guard let refreshedToken = await tokenRefreshGate.refresh(
      staleToken: staleToken,
      using: tokenRefreshHandler
    ) else { return nil }
    var retryRequest = request
    retryRequest.setValue("Bearer \(refreshedToken)", forHTTPHeaderField: "Authorization")
    return retryRequest
  }

  private func makeURLRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
    guard let baseURL = serverURLProvider() else {
      throw NetworkError.missingServerURL
    }
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      throw NetworkError.invalidURL
    }

    let path = endpoint.path.hasPrefix("/") ? endpoint.path : "/\(endpoint.path)"
    let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
    components.path = "\(basePath)\(path)"
    components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

    guard let url = components.url else { throw NetworkError.invalidURL }
    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    request.httpBody = endpoint.body

    if endpoint.body != nil, endpoint.headers["Content-Type"] == nil {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    for (key, value) in endpoint.headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    if endpoint.requiresAuth {
      guard let token = accessTokenProvider() else {
        throw NetworkError.missingAccessToken
      }
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    AppLogger.network.debug("Request \(request.httpMethod ?? "") \(url.absoluteString)")
    return request
  }

  private func errorMessage(from data: Data) -> String? {
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      if let message = json["error"] as? String { return message }
      if let message = json["message"] as? String { return message }
    }
    let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return text?.isEmpty == true ? nil : text
  }

  private func bearerToken(from request: URLRequest) -> String? {
    guard let header = request.value(forHTTPHeaderField: "Authorization") else { return nil }
    let prefix = "Bearer "
    guard header.hasPrefix(prefix) else { return nil }
    let token = String(header.dropFirst(prefix.count))
    return token.isEmpty ? nil : token
  }
}

private actor TokenRefreshGate {
  private var inFlight: Task<String?, Never>?

  func refresh(
    staleToken: String,
    using handler: @escaping URLSessionAPIClient.TokenRefreshHandler
  ) async -> String? {
    if let inFlight {
      return await inFlight.value
    }
    let task = Task<String?, Never> {
      try? await handler(staleToken)
    }
    inFlight = task
    let token = await task.value
    inFlight = nil
    return token
  }
}
