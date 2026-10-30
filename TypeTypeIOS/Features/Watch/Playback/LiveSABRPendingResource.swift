import Foundation

enum LiveSABRPendingResource {
  static let pollLimit = 120

  static func load(_ url: URL, service: LivePlaybackServiceProtocol) async throws -> Data {
    for attempt in 0..<pollLimit {
      try Task.checkCancellation()
      let data = try await service.resourceData(for: url)
      guard let retryAfter = retryDelay(for: data, upstreamURL: url) else {
        return data
      }
      guard attempt + 1 < pollLimit else { break }
      try await Task.sleep(for: .milliseconds(retryAfter))
    }
    throw LivePlaybackFailure.sabrSessionTimedOut
  }

  static func retryDelay(for data: Data, upstreamURL: URL) -> Int? {
    guard upstreamURL.scheme == LivePlaybackService.authenticatedScheme,
      upstreamURL.path.contains("/sabr/playback/"),
      data.first == UInt8(ascii: "{"),
      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      response["ready"] as? Bool == false
    else {
      return nil
    }
    let requested = response["retryAfterMs"] as? NSNumber
    return min(max(requested?.intValue ?? 500, 50), 2_000)
  }
}
