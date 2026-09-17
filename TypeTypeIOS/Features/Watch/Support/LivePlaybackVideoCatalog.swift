import Foundation

enum LivePlaybackVideoCatalog {
  static func resolutionOptions(
    from sources: [LivePlaybackVideoSource]
  ) -> [LivePlaybackVideoSource] {
    let playable = sources.filter { $0.height > 0 }
    let grouped = Dictionary(grouping: playable, by: \.height)
    return grouped.compactMap { _, variants in
      variants.max { lhs, rhs in
        let lhsBitrate = lhs.bitrate ?? 0
        let rhsBitrate = rhs.bitrate ?? 0
        if lhsBitrate != rhsBitrate {
          return lhsBitrate < rhsBitrate
        }
        return lhs.fps < rhs.fps
      }
    }
    .sorted { $0.height < $1.height }
  }

  static func qualityLabel(for source: LivePlaybackVideoSource) -> String {
    var label = source.displayName
    if source.fps > 0, source.fps != 30 {
      label += "\(source.fps)"
    }
    return label
  }

  static func codecLabel(for source: LivePlaybackVideoSource) -> String? {
    let codec = source.codec?.lowercased() ?? ""
    if codec.hasPrefix("avc1") { return "H.264" }
    if codec.hasPrefix("hvc1") || codec.hasPrefix("hev1") {
      return "HEVC"
    }
    if codec.hasPrefix("av01") { return "AV1" }
    if codec.hasPrefix("vp09") || codec.hasPrefix("vp9") { return "VP9" }
    return source.codec
  }

  static func detailLabel(for source: LivePlaybackVideoSource) -> String {
    var parts = [qualityLabel(for: source)]
    if let codec = codecLabel(for: source), !codec.isEmpty {
      parts.append(codec)
    }
    if let bitrate = source.bitrate, bitrate > 0 {
      parts.append(bitrate >= 1_000_000
        ? String(format: "%.1f Mbps", Double(bitrate) / 1_000_000)
        : "\(bitrate / 1000) kbps")
    }
    return parts.joined(separator: " · ")
  }
}
