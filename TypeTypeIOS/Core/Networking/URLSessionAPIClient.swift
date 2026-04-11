import Foundation

final class URLSessionAPIClient: APIClient {
  private let serverURLProvider: () -> URL?
  private let accessTokenProvider: () -> String?
  private let session: URLSession
  private let decoder = JSONDecoder()

  init(
    serverURLProvider: @escaping () -> URL?,
    accessTokenProvider: @escaping () -> String?,
    session: URLSession = .shared
  ) {
    self.serverURLProvider = serverURLProvider
    self.accessTokenProvider = accessTokenProvider
    self.session = session
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
}
