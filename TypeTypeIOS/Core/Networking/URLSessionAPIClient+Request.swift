import Foundation

extension URLSessionAPIClient {
  func makeURLRequest(
    _ endpoint: APIEndpoint
  ) throws -> URLRequest {
    guard let baseURL = serverURLProvider() else {
      throw NetworkError.missingServerURL
    }
    guard var components = URLComponents(
      url: baseURL,
      resolvingAgainstBaseURL: false
    ) else {
      throw NetworkError.invalidURL
    }

    let path = endpoint.path.hasPrefix("/")
      ? endpoint.path
      : "/\(endpoint.path)"
    let basePath = components.path.hasSuffix("/")
      ? String(components.path.dropLast())
      : components.path
    components.path = "\(basePath)\(path)"
    components.queryItems = endpoint.queryItems.isEmpty
      ? nil
      : endpoint.queryItems

    guard let url = components.url else {
      throw NetworkError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    request.httpBody = endpoint.body
    request.httpShouldHandleCookies = endpoint.handlesCookies
    if let timeoutInterval = endpoint.timeoutInterval {
      request.timeoutInterval = timeoutInterval
    }
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if endpoint.body != nil, endpoint.headers["Content-Type"] == nil {
      request.setValue(
        "application/json",
        forHTTPHeaderField: "Content-Type"
      )
    }
    for (key, value) in endpoint.headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    if endpoint.requiresAuth {
      guard let token = accessTokenProvider() else {
        throw NetworkError.missingAccessToken
      }
      request.setValue(
        "Bearer \(token)",
        forHTTPHeaderField: "Authorization"
      )
    }

    AppLogger.network.debug(
      "\(endpoint.method.rawValue, privacy: .public) \(url.path, privacy: .public)"
    )
    return request
  }

  func errorMessage(from data: Data) -> String? {
    if let json = try? JSONSerialization.jsonObject(with: data)
      as? [String: Any] {
      if let message = json["error"] as? String {
        return message
      }
      if let message = json["message"] as? String {
        return message
      }
    }
    let text = String(data: data, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let text, !text.isEmpty else { return nil }
    return String(text.prefix(500))
  }

  static func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.default
    configuration.httpCookieAcceptPolicy = .always
    configuration.httpCookieStorage = .shared
    configuration.httpShouldSetCookies = true
    configuration.requestCachePolicy = .reloadRevalidatingCacheData
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 120
    configuration.waitsForConnectivity = true
    return URLSession(configuration: configuration)
  }

  /// Segments are read once and played: caching them on disk only costs
  /// writes. Kept apart so a burst of API calls never queues ahead of video.
  static func makeMediaSession() -> URLSession {
    let configuration = URLSessionConfiguration.default
    configuration.httpCookieAcceptPolicy = .always
    configuration.httpCookieStorage = .shared
    configuration.httpShouldSetCookies = true
    configuration.urlCache = nil
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.timeoutIntervalForRequest = 30
    configuration.timeoutIntervalForResource = 180
    configuration.waitsForConnectivity = true
    return URLSession(configuration: configuration)
  }
}

/// Raises each media task to the highest priority the session offers.
final class MediaTaskPriority: NSObject, URLSessionTaskDelegate, Sendable {

  func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
    task.priority = URLSessionTask.highPriority
  }
}
