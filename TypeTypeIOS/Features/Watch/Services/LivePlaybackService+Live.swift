import Foundation

extension LivePlaybackService {
  /// YouTube lives have no SABR formats: the server gives an HLS manifest
  /// (`/streams/hls-manifest?token=…`, relative to the API base and signed by
  /// its token), which the native player plays with its own live controls.
  func prepareLiveHLS(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    guard let manifestURL = serverResourceURL(for: stream.hlsURL) else {
      throw LivePlaybackFailure.noPlayableSource
    }
    return LivePlaybackPreparation(
      stream: stream,
      assetURL: manifestURL,
      usesAuthenticatedLoader: false,
      video: nil,
      audio: nil,
      providerPlayback: nil,
      subtitles: [],
      resumeTime: 0,
      isSABR: false,
      audioOnly: preferences.audioOnly
    )
  }

  /// Absolute URL for a server resource: absolute values are kept, relative
  /// ones (`/media/…`, `/streams/hls-manifest?…`) are resolved against the
  /// selected server's API base, where the server serves them.
  func serverResourceURL(for value: String) -> URL? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, let resource = URLComponents(string: trimmed) else { return nil }
    if let scheme = resource.scheme, !scheme.isEmpty {
      return resource.url
    }
    guard let serverURL = serverURLProvider(),
      var server = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)
    else { return nil }
    let base = server.path.hasSuffix("/") ? String(server.path.dropLast()) : server.path
    let path = resource.path.hasPrefix("/") ? resource.path : "/\(resource.path)"
    server.path = base + path
    server.queryItems = resource.queryItems
    return server.url
  }

  static func playsAsLiveHLS(_ stream: LivePlaybackStream) -> Bool {
    stream.isLive && !stream.hlsURL.isEmpty
  }
}
