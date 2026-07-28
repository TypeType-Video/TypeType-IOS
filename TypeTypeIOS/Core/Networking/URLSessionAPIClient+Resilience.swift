import Foundation

extension URLSessionAPIClient {
  func executeRead<T>(
    _ request: URLRequest,
    operation: () async throws -> T
  ) async throws -> T {
    let maximumAttempts = request.httpMethod == HTTPMethod.get.rawValue
      ? 3
      : 1
    var attempt = 0
    while true {
      do {
        return try await operation()
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        attempt += 1
        guard attempt < maximumAttempts,
          Self.isTransientReadFailure(error)
        else {
          throw error
        }
        let delays = [200, 600]
        try await Task.sleep(
          for: .milliseconds(delays[min(attempt - 1, delays.count - 1)])
        )
      }
    }
  }

  private static func isTransientReadFailure(
    _ error: Error
  ) -> Bool {
    guard let networkError = error as? NetworkError else {
      return false
    }
    switch networkError {
    case .transport:
      return true
    case let .statusCode(code, _):
      return [408, 425, 429, 500, 502, 503, 504]
        .contains(code)
    default:
      return false
    }
  }

  func makeRetryRequest(
    from request: URLRequest
  ) async -> URLRequest? {
    guard let tokenRefreshHandler else { return nil }
    guard let staleToken = bearerToken(from: request) else { return nil }
    guard let refreshedToken = await tokenRefreshGate.refresh(
      staleToken: staleToken,
      using: tokenRefreshHandler
    ) else {
      return nil
    }
    var retryRequest = request
    retryRequest.setValue(
      "Bearer \(refreshedToken)",
      forHTTPHeaderField: "Authorization"
    )
    return retryRequest
  }

  private func bearerToken(from request: URLRequest) -> String? {
    guard let header = request.value(
      forHTTPHeaderField: "Authorization"
    ) else {
      return nil
    }
    let prefix = "Bearer "
    guard header.hasPrefix(prefix) else { return nil }
    let token = String(header.dropFirst(prefix.count))
    return token.isEmpty ? nil : token
  }
}
