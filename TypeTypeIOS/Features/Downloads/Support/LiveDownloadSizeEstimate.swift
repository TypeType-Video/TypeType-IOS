import Foundation

// Same choice as the server's downloader (MP4: best video of the requested codec up to the height, best mp4a audio
// favouring the default then original track): the estimate then matches the file it builds.
enum LiveDownloadSizeEstimate {
  static func bytes(
    for stream: LivePlaybackStream,
    mode: LiveDownloadMode,
    quality: String,
    videoCodecPrefix: String = "avc1"
  ) -> Int64? {
    let audio = bestAudio(in: stream).flatMap { size(of: $0.contentLength, bitrate: $0.bitrate, duration: stream.duration) }
    switch mode {
    case .thumbnail:
      return nil
    case .audio:
      return audio
    case .video:
      let maxHeight = Int(quality.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)) ?? 1080
      guard let video = bestVideo(in: stream, maxHeight: maxHeight, codecPrefix: videoCodecPrefix),
        let videoBytes = size(of: video.contentLength, bitrate: video.bitrate, duration: stream.duration)
      else { return nil }
      return videoBytes + (audio ?? 0)
    }
  }

  private static func bestVideo(
    in stream: LivePlaybackStream,
    maxHeight: Int,
    codecPrefix: String
  ) -> LivePlaybackVideoSource? {
    stream.videoOnlyStreams
      .filter { $0.mimeType.contains("mp4") && ($0.codec ?? "").isEmptyOrPrefixed(codecPrefix) && $0.height <= maxHeight }
      .max { ($0.height, $0.bitrate ?? 0) < ($1.height, $1.bitrate ?? 0) }
  }

  private static func bestAudio(in stream: LivePlaybackStream) -> LivePlaybackAudioSource? {
    stream.audioStreams
      .filter { $0.mimeType.contains("mp4") && ($0.codec ?? "").isEmptyOrPrefixed("mp4a") }
      .max { rank($0, stream) < rank($1, stream) }
  }

  private static func rank(_ audio: LivePlaybackAudioSource, _ stream: LivePlaybackStream) -> Int {
    var rank = audio.bitrate ?? 0
    if let preferred = stream.preferredDefaultAudioTrackID, audio.audioTrackID == preferred { rank += 1_000_000 }
    if audio.isOriginal { rank += 500_000 }
    return rank
  }

  private static func size(of contentLength: Int64, bitrate: Int?, duration: Int64) -> Int64? {
    if contentLength > 0 { return contentLength }
    guard let bitrate, bitrate > 0, duration > 0 else { return nil }
    return Int64(bitrate) * duration / 8
  }
}

private extension String {
  func isEmptyOrPrefixed(_ prefix: String) -> Bool {
    isEmpty || hasPrefix(prefix)
  }
}
