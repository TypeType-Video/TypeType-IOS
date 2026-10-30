import Foundation

extension LivePlaybackServiceProtocol {
  func playbackStream(for videoURL: String) async throws -> LivePlaybackStream {
    try await stream(for: videoURL)
  }

  func discardPendingStreams(for videoURL: String) async {}
}

extension LivePlaybackService {
  func playbackStream(for videoURL: String) async throws -> LivePlaybackStream {
    if let full = streamCache.stream(for: videoURL, ttl: Self.streamCacheTTL) {
      return full
    }
    guard isYouTubeURL(videoURL) else { return try await stream(for: videoURL) }
    if let ready = playbackCache.stream(for: videoURL, ttl: Self.streamCacheTTL) {
      return ready
    }
    do {
      let ready = try await requests.value(for: "bootstrap|" + videoURL) { [self] in
        // A refused bootstrap (503 for lives) is an answer: fall back now.
        try await requestStream(
          path: "/streams/youtube/sabr/bootstrap",
          videoURL: videoURL,
          retriesTransientFailures: false
        )
      }
      playbackCache.store(ready, for: videoURL)
      return ready
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      return try await stream(for: videoURL)
    }
  }

  // A startup retry must ask again: joining the request that blew the budget only waits longer.
  func discardPendingStreams(for videoURL: String) async {
    await requests.discard("full|" + videoURL)
    await requests.discard("bootstrap|" + videoURL)
  }
}
