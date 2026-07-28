import Foundation

extension LivePlaybackService {
  func sabrRequest<T: Decodable>(
    _ endpoint: APIEndpoint,
    as type: T.Type
  ) async throws -> T {
    var failureCount = 0
    while true {
      do {
        return try await apiClient.request(endpoint, as: type)
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        failureCount += 1
        guard let delayMS = Self.sabrRetryDelayMS(
          for: error,
          failureCount: failureCount
        ) else {
          throw error
        }
        try await Task.sleep(for: .milliseconds(delayMS))
      }
    }
  }

  static func sabrRetryDelayMS(
    for error: Error,
    failureCount: Int
  ) -> Int? {
    guard failureCount > 0, failureCount <= 24 else { return nil }
    guard let networkError = error as? NetworkError else { return nil }
    switch networkError {
    case .transport:
      break
    case let .statusCode(code, _):
      guard [502, 503, 504].contains(code) else { return nil }
    default:
      return nil
    }
    let exponent = min(failureCount - 1, 3)
    return min(500 * (1 << exponent), 3_000)
  }
}
