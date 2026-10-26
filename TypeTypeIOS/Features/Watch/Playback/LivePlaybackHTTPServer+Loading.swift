import Foundation

extension LivePlaybackHTTPServer {
  func loadProviderRange(
    _ url: URL,
    range: ClosedRange<Int>,
    allowsAdaptiveRetry: Bool = true
  ) async throws -> Data {
    try await LiveProviderRangeLoader(service: service).load(
      url,
      range: range,
      allowsAdaptiveRetry: allowsAdaptiveRetry
    )
  }

  func loadUpstream(_ url: URL) async throws -> Resource {
    let data = try await LiveSABRPendingResource.load(url, service: service)
    if isPlaylist(data) {
      return Resource(
        data: try rewritePlaylist(data, upstreamURL: url),
        mimeType: Self.playlistMIME
      )
    }
    return Resource(
      data: data,
      mimeType: upstreamMIMEType(for: url)
    )
  }

}
