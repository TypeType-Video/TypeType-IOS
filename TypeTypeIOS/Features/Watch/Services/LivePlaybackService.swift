import Foundation

protocol LivePlaybackServiceProtocol: AnyObject {
  func stream(for videoURL: String) async throws -> LivePlaybackStream
  func prepare(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation
  func resourceData(for assetURL: URL) async throws -> Data
  func subtitleData(for source: LivePlaybackSubtitle) async throws -> Data
}

final class LivePlaybackService: LivePlaybackServiceProtocol {
  private let apiClient: APIClient
  private let serverURLProvider: () -> URL?

  init(
    apiClient: APIClient,
    serverURLProvider: @escaping () -> URL?
  ) {
    self.apiClient = apiClient
    self.serverURLProvider = serverURLProvider
  }

  func stream(for videoURL: String) async throws -> LivePlaybackStream {
    try await apiClient.request(
      APIEndpoint(
        path: streamPath(for: videoURL),
        method: .get,
        queryItems: [URLQueryItem(name: "url", value: videoURL)],
        requiresAuth: true,
        timeoutInterval: 120
      ),
      as: LivePlaybackStream.self
    )
  }

  func prepare(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    if stream.isYouTube {
      return try prepareYouTubeSABR(
        stream: stream,
        preferences: preferences
      )
    }
    return try prepareProviderPlayback(
      stream: stream,
      preferences: preferences
    )
  }

  func resourceData(for assetURL: URL) async throws -> Data {
    let endpoint = try serverEndpoint(for: assetURL)
    return try await apiClient.requestData(endpoint)
  }

  func subtitleData(for source: LivePlaybackSubtitle) async throws -> Data {
    guard let sourceURL = URL(string: source.url) else {
      throw LivePlaybackFailure.invalidServerResource
    }
    if isSelectedServerURL(sourceURL) {
      return try await resourceData(
        for: authenticatedAssetURL(for: sourceURL)
      )
    }
    guard var components = URLComponents(
      url: sourceURL,
      resolvingAgainstBaseURL: false
    ) else {
      throw LivePlaybackFailure.invalidServerResource
    }
    var items = components.queryItems ?? []
    if !items.contains(where: { $0.name == "fmt" }) {
      items.append(URLQueryItem(name: "fmt", value: "vtt"))
      components.queryItems = items
    }
    guard let vttURL = components.url else {
      throw LivePlaybackFailure.invalidServerResource
    }
    return try await apiClient.requestData(
      APIEndpoint(
        path: "/proxy",
        method: .get,
        queryItems: [
          URLQueryItem(name: "url", value: vttURL.absoluteString)
        ],
        requiresAuth: true,
        timeoutInterval: 120
      )
    )
  }

  private func prepareYouTubeSABR(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    let videos = stream.allVideoSources.filter {
      $0.isSABR && $0.isAppleH264 && $0.itag > 0
    }
    let audios = stream.audioStreams.filter {
      $0.isSABR && $0.isAppleAAC && $0.itag > 0
    }
    let video = selectVideo(
      from: videos,
      quality: preferences.quality,
      requestedItag: preferences.videoItag
    )
    let audio = selectAudio(
      from: audios,
      requestedTrackID: preferences.audioTrackID
    )
    guard let video, let audio else {
      throw LivePlaybackFailure.noPlayableSource
    }
    guard let serverURL = serverURLProvider(),
      var components = URLComponents(
        url: serverURL,
        resolvingAgainstBaseURL: false
      )
    else {
      throw NetworkError.missingServerURL
    }
    let basePath = components.path.hasSuffix("/")
      ? String(components.path.dropLast())
      : components.path
    components.path = "\(basePath)/sabr/manifest/\(stream.id)"
    var query = [
      URLQueryItem(name: "format", value: "hls"),
      URLQueryItem(name: "videoItag", value: String(video.itag)),
      URLQueryItem(name: "audioItag", value: String(audio.itag)),
    ]
    if let audioTrackID = audio.audioTrackID, !audioTrackID.isEmpty {
      query.append(
        URLQueryItem(name: "audioTrackId", value: audioTrackID)
      )
    }
    if preferences.audioOnly {
      query.append(URLQueryItem(name: "audioOnly", value: "true"))
    }
    components.queryItems = query
    guard let manifestURL = components.url else {
      throw LivePlaybackFailure.invalidServerResource
    }
    return LivePlaybackPreparation(
      stream: stream,
      assetURL: authenticatedAssetURL(for: manifestURL),
      usesAuthenticatedLoader: true,
      video: preferences.audioOnly ? nil : video,
      audio: audio,
      subtitles: stream.subtitles,
      resumeTime: TimeInterval(max(stream.startPosition, 0)),
      isSABR: true
    )
  }

  private func prepareProviderPlayback(
    stream: LivePlaybackStream,
    preferences: LivePlaybackPreferences
  ) throws -> LivePlaybackPreparation {
    if let hlsURL = URL(string: stream.hlsURL), !stream.hlsURL.isEmpty {
      let isServer = isSelectedServerURL(hlsURL)
      return LivePlaybackPreparation(
        stream: stream,
        assetURL: isServer ? authenticatedAssetURL(for: hlsURL) : hlsURL,
        usesAuthenticatedLoader: isServer,
        video: nil,
        audio: nil,
        subtitles: stream.subtitles,
        resumeTime: TimeInterval(max(stream.startPosition, 0)),
        isSABR: false
      )
    }
    let muxed = stream.videoStreams.filter {
      !$0.isVideoOnly && !$0.url.isEmpty
        && $0.mimeType.lowercased().hasPrefix("video/mp4")
    }
    guard let selected = selectVideo(
      from: muxed,
      quality: preferences.quality,
      requestedItag: preferences.videoItag
    ), let url = URL(string: selected.url) else {
      throw LivePlaybackFailure.noPlayableSource
    }
    return LivePlaybackPreparation(
      stream: stream,
      assetURL: url,
      usesAuthenticatedLoader: false,
      video: selected,
      audio: nil,
      subtitles: stream.subtitles,
      resumeTime: TimeInterval(max(stream.startPosition, 0)),
      isSABR: false
    )
  }

  private func selectVideo(
    from sources: [LivePlaybackVideoSource],
    quality: String,
    requestedItag: Int?
  ) -> LivePlaybackVideoSource? {
    if let requestedItag,
      let requested = sources.first(where: { $0.itag == requestedItag }) {
      return requested
    }
    let target = qualityHeight(quality)
    let ordered = sources.sorted {
      if $0.height != $1.height { return $0.height < $1.height }
      return ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
    }
    if let target {
      return ordered.last(where: { $0.height <= target })
        ?? ordered.first
    }
    return ordered.last
  }

  private func selectAudio(
    from sources: [LivePlaybackAudioSource],
    requestedTrackID: String?
  ) -> LivePlaybackAudioSource? {
    let deduplicated = Dictionary(
      grouping: sources,
      by: \.id
    ).compactMap { $0.value.max(by: {
      ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
    }) }
    if let requestedTrackID, !requestedTrackID.isEmpty,
      let requested = deduplicated.first(where: {
        $0.audioTrackID == requestedTrackID
      }) {
      return requested
    }
    return deduplicated.first(where: \.isOriginal)
      ?? deduplicated.max(by: {
        ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
      })
  }

  private func qualityHeight(_ quality: String) -> Int? {
    let digits = quality.prefix { $0.isNumber }
    return Int(digits)
  }

  private func streamPath(for rawURL: String) -> String {
    guard let host = URL(string: rawURL)?.host?.lowercased() else {
      return "/streams"
    }
    if host == "youtu.be" || host == "youtube.com"
      || host.hasSuffix(".youtube.com")
      || host == "youtube-nocookie.com"
      || host.hasSuffix(".youtube-nocookie.com") {
      return "/streams/youtube/sabr/bootstrap"
    }
    if host == "nicovideo.jp" || host.hasSuffix(".nicovideo.jp")
      || host == "nico.ms" {
      return "/streams/niconico"
    }
    if host == "bilibili.com" || host.hasSuffix(".bilibili.com")
      || host == "b23.tv" {
      return "/streams/bilibili"
    }
    return "/streams"
  }

  private func serverEndpoint(for assetURL: URL) throws -> APIEndpoint {
    guard assetURL.scheme == Self.authenticatedScheme,
      let serverURL = serverURLProvider(),
      let components = URLComponents(
        url: assetURL,
        resolvingAgainstBaseURL: false
      )
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    guard components.host?.caseInsensitiveCompare(
      serverURL.host ?? ""
    ) == .orderedSame,
      components.port == serverURL.port
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    let serverPath = serverURL.path.hasSuffix("/")
      ? String(serverURL.path.dropLast())
      : serverURL.path
    guard components.path == serverPath
      || components.path.hasPrefix("\(serverPath)/")
    else {
      throw LivePlaybackFailure.invalidServerResource
    }
    let relativePath = String(components.path.dropFirst(serverPath.count))
    return APIEndpoint(
      path: relativePath.isEmpty ? "/" : relativePath,
      method: .get,
      queryItems: components.queryItems ?? [],
      requiresAuth: true,
      timeoutInterval: 180
    )
  }

  private func authenticatedAssetURL(for url: URL) -> URL {
    guard var components = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    ) else {
      return url
    }
    components.scheme = Self.authenticatedScheme
    return components.url ?? url
  }

  private func isSelectedServerURL(_ url: URL) -> Bool {
    guard let serverURL = serverURLProvider() else { return false }
    return url.scheme?.caseInsensitiveCompare(
      serverURL.scheme ?? ""
    ) == .orderedSame
      && url.host?.caseInsensitiveCompare(
        serverURL.host ?? ""
      ) == .orderedSame
      && url.port == serverURL.port
      && (url.path == serverURL.path
        || url.path.hasPrefix(
          serverURL.path.hasSuffix("/")
            ? serverURL.path
            : "\(serverURL.path)/"
        ))
  }

  private static let authenticatedScheme = "typetype-sabr"
}

private extension LivePlaybackStream {
  var isYouTube: Bool {
    allVideoSources.contains(where: \.isSABR)
      && audioStreams.contains(where: \.isSABR)
  }
}
