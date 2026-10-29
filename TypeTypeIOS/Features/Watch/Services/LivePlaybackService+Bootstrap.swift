import Foundation

extension LivePlaybackServiceProtocol {
  /// Services without a faster playback contract start from full metadata.
  func playbackStream(for videoURL: String) async throws -> LivePlaybackStream {
    try await stream(for: videoURL)
  }

  func discardPendingStreams(for videoURL: String) async {}
}

extension LivePlaybackService {
  /// YouTube starts from the SABR bootstrap (0.1 to 0.2 s, against 1.3 to 1.8 s for full extraction);
  /// metadata comes later from `stream(for:)`. Lives have no bootstrap and take the full route.
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

  // A startup retry must ask again: joining the request that blew the startup budget only waits longer.
  func discardPendingStreams(for videoURL: String) async {
    await requests.discard("full|" + videoURL)
    await requests.discard("bootstrap|" + videoURL)
  }
}
