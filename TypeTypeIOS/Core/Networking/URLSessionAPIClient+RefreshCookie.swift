import Foundation

extension URLSessionAPIClient {
  static let refreshCookieName = "refresh_token"

  // The server rotates this cookie on every refresh, and the shared cookie storage only reaches the disk
  // later: an app killed in between wakes up with a dead token. The Keychain copy is written right away.
  func captureRefreshCookie(from response: HTTPURLResponse) {
    guard let refreshCookieObserver, let url = response.url else { return }
    var fields: [String: String] = [:]
    for (key, value) in response.allHeaderFields {
      if let key = key as? String, let value = value as? String {
        fields[key] = value
      }
    }
    for cookie in HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
    where cookie.name == Self.refreshCookieName {
      refreshCookieObserver(cookie.value.isEmpty ? nil : cookie.value)
    }
  }
}
