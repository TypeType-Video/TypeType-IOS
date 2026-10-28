import Foundation

extension LivePlaybackServiceProtocol {
  /// Services without a faster playback contract start from full metadata.
  func playbackStream(for videoURL: String) async throws -> LivePlaybackStream {
    try await stream(for: videoURL)
  }

  func discardPendingStreams(for videoURL: String) async {}
}

extension LivePlaybackService {
  /// The stream needed to start playing, as fast as the server can give it.
  /// For YouTube that is the SABR bootstrap (about 0.1–0.2 s against 1.3–1.8 s
  /// for full extraction, like Android's PlayerStreamLoader); full metadata
  /// (related videos, chapters) is fetched separately with `stream(for:)`.
  /// Lives have no bootstrap contract and fall back to the full route at once.
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
