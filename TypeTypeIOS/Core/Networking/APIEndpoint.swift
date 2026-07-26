import Foundation

struct APIEndpoint {
  let path: String
  let method: HTTPMethod
  let queryItems: [URLQueryItem]
  let headers: [String: String]
  let body: Data?
  let requiresAuth: Bool
  let timeoutInterval: TimeInterval?

  init(
    path: String,
    method: HTTPMethod,
    queryItems: [URLQueryItem] = [],
    headers: [String: String] = [:],
    body: Data? = nil,
    requiresAuth: Bool = false,
    timeoutInterval: TimeInterval? = nil
  ) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.headers = headers
    self.body = body
    self.requiresAuth = requiresAuth
    self.timeoutInterval = timeoutInterval
  }

  static func jsonBody<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(value)
  }
}
