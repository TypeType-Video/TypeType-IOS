import Foundation

extension LivePlaybackService {
  func selectVideo(
    from sources: [LivePlaybackVideoSource],
    quality: String,
    preferredCodec: String = "recommended",
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
    let codecCandidates = filteredByCodec(
      sources,
      preferredCodec: preferredCodec
    )
    let codecOrdered = codecCandidates.isEmpty ? sources : codecCandidates
    let ordered = codecOrdered.sorted {
      if $0.height != $1.height { return $0.height < $1.height }
      // Same height: the more efficient codec wins (fewer bytes to start).
      let lhsRank = Self.codecEfficiencyRank($0.codec)
      let rhsRank = Self.codecEfficiencyRank($1.codec)
      if lhsRank != rhsRank { return lhsRank < rhsRank }
      return ($0.bitrate ?? 0) < ($1.bitrate ?? 0)
    }
    if let target {
      return ordered.last(where: { $0.height <= target })
        ?? ordered.first
    }
    return ordered.last
  }

  /// Higher is preferred at equal height among sources iOS can play.
  static func codecEfficiencyRank(_ codec: String?) -> Int {
    let codec = codec?.lowercased() ?? ""
    if codec.hasPrefix("hvc1") { return 2 }
    if codec.hasPrefix("avc1") { return 1 }
    return 0
  }

  private func filteredByCodec(
    _ sources: [LivePlaybackVideoSource],
    preferredCodec: String
  ) -> [LivePlaybackVideoSource] {
    let prefixes: [String]
    switch preferredCodec.lowercased() {
    case "av1": prefixes = ["av01"]
    case "vp9": prefixes = ["vp09", "vp9"]
    case "h264": prefixes = ["avc1"]
    default: return sources
    }
    return sources.filter { source in
      prefixes.contains {
        source.codec?.lowercased().hasPrefix($0) == true
      }
    }
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
