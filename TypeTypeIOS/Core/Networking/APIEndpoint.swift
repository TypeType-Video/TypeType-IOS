import Foundation

struct APIEndpoint {
  let path: String
  let method: HTTPMethod
  let queryItems: [URLQueryItem]
  let headers: [String: String]
  let body: Data?
  let requiresAuth: Bool
  let timeoutInterval: TimeInterval?
  // False when a failure is an answer (a route that refuses some videos): fall back at once, no retries.
  let retriesTransientFailures: Bool
  let isMedia: Bool
  let handlesCookies: Bool

  init(
    path: String,
    method: HTTPMethod,
    queryItems: [URLQueryItem] = [],
    headers: [String: String] = [:],
    body: Data? = nil,
    requiresAuth: Bool = false,
    timeoutInterval: TimeInterval? = nil,
    retriesTransientFailures: Bool = true,
    isMedia: Bool = false,
    handlesCookies: Bool = true
  ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.headers = headers
    self.body = body
    self.requiresAuth = requiresAuth
    self.timeoutInterval = timeoutInterval
    self.retriesTransientFailures = retriesTransientFailures
    self.isMedia = isMedia
    self.handlesCookies = handlesCookies
  }

  func asMedia() -> APIEndpoint {
    APIEndpoint(
      path: path,
      method: method,
      queryItems: queryItems,
      headers: headers,
      body: body,
      requiresAuth: requiresAuth,
      timeoutInterval: timeoutInterval,
      retriesTransientFailures: retriesTransientFailures,
      isMedia: true,
      handlesCookies: handlesCookies
    )
  }

  static func jsonBody<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(value)
  }
}
