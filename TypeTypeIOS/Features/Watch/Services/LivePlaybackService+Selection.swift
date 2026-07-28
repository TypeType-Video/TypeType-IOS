import Foundation

extension LivePlaybackService {
  func selectVideo(
    from sources: [LivePlaybackVideoSource],
    quality: String,
    requestedItag: Int?,
    requestedSourceID: String? = nil
  ) -> LivePlaybackVideoSource? {
    if let requestedSourceID,
      let requested = sources.first(where: {
        $0.selectionID == requestedSourceID
      }) {
      return requested
    }
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

  func selectAudio(
    from sources: [LivePlaybackAudioSource],
    requestedTrackID: String?,
    requestedSourceID: String? = nil
  ) -> LivePlaybackAudioSource? {
    let deduplicated = Dictionary(
      grouping: sources,
      by: \.id
    ).compactMap { $0.value.max(by: {
      ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
    }) }
    if let requestedSourceID,
      let requested = deduplicated.first(where: {
        $0.id == requestedSourceID
      }) {
      return requested
    }
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

  func providerDeliveryMethod(
    declared: String,
    sourceURL: URL
  ) -> String {
    if sourceURL.pathExtension.caseInsensitiveCompare("m3u8")
      == .orderedSame {
      return "hls"
    }
    return declared.lowercased()
  }

  func providerProxyURL(
    for sourceURL: URL,
    authenticated: Bool
  ) -> URL? {
    guard let serverURL = serverURLProvider(),
      var components = URLComponents(
        url: serverURL,
        resolvingAgainstBaseURL: false
      )
    else {
      return nil
    }
    let basePath = components.path.hasSuffix("/")
      ? String(components.path.dropLast())
      : components.path
    components.path = "\(basePath)/proxy"
    components.queryItems = [
      URLQueryItem(name: "url", value: sourceURL.absoluteString),
    ]
    if authenticated {
      components.scheme = Self.authenticatedScheme
    }
    return components.url
  }
}
