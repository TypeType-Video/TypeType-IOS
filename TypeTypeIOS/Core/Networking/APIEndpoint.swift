import Foundation

struct APIEndpoint {
  let path: String
  let method: HTTPMethod
  let queryItems: [URLQueryItem]
  let headers: [String: String]
  let body: Data?
  let requiresAuth: Bool
  let timeoutInterval: TimeInterval?
  /// False when a failure is an answer, not a hiccup (a route that refuses
  /// some videos), so the caller falls back at once instead of after retries.
  let retriesTransientFailures: Bool

  init(
    path: String,
    method: HTTPMethod,
    queryItems: [URLQueryItem] = [],
    headers: [String: String] = [:],
    body: Data? = nil,
    requiresAuth: Bool = false,
    timeoutInterval: TimeInterval? = nil,
    retriesTransientFailures: Bool = true
  ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.headers = headers
    self.body = body
    self.requiresAuth = requiresAuth
    self.timeoutInterval = timeoutInterval
    self.retriesTransientFailures = retriesTransientFailures
  }

  static func jsonBody<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(value)
  }
}
