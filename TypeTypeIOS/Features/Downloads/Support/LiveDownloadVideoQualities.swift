import CoreMedia
import VideoToolbox

struct LiveDownloadVideoQuality: Equatable {
  let height: Int
  let codecPrefix: String

  var value: String { "\(height)p" }

  // The downloader matches this as a codec prefix; it maps "h264" to avc1 itself.
  var requestCodec: String { codecPrefix == "avc1" ? "h264" : codecPrefix }
}

struct LiveDownloadVideoQualities: Equatable {
  static let fallback = [1080, 720, 480, 360].map { LiveDownloadVideoQuality(height: $0, codecPrefix: "avc1") }

  let options: [LiveDownloadVideoQuality]
  let hidesUnplayableHigherQualities: Bool

  // YouTube stops H.264 at 1080p; anything above is VP9 or AV1, and AVPlayer only plays AV1 on chips that decode it.
  init(
    stream: LivePlaybackStream,
    decodesInHardware: (CMVideoCodecType) -> Bool = VTIsHardwareDecodeSupported
  ) {
    var playable = ["avc1"]
    if decodesInHardware(kCMVideoCodecType_HEVC) {
      playable += ["hvc1", "hev1"]
    }
    if decodesInHardware(kCMVideoCodecType_AV1) {
      playable.append("av01")
    }
    let sources = stream.videoOnlyStreams.filter { $0.height > 0 && $0.mimeType.contains("mp4") && $0.isDownloadable }
    let codecsByHeight = Dictionary(grouping: sources, by: \.height).mapValues { Set($0.map(\.codecPrefix)) }
    let options = codecsByHeight.compactMap { height, codecs in
      playable.first { codecs.contains($0) }.map { LiveDownloadVideoQuality(height: height, codecPrefix: $0) }
    }
    .sorted { $0.height > $1.height }
    self.options = options.isEmpty ? Self.fallback : options
    let highest = options.first?.height ?? 0
    hidesUnplayableHigherQualities = codecsByHeight.keys.contains { $0 > highest }
  }

  init(options: [LiveDownloadVideoQuality] = Self.fallback) {
    self.options = options
    hidesUnplayableHigherQualities = false
  }

  func option(for value: String) -> LiveDownloadVideoQuality? {
    options.first { $0.value == value }
  }

  var defaultValue: String {
    (options.first { $0.height <= 1080 } ?? options.last)?.value ?? "1080p"
  }
}

private extension LivePlaybackVideoSource {
  var isDownloadable: Bool {
    !url.isEmpty || deliveryMethod == "sabr" && !(manifestURL ?? "").isEmpty
  }

  var codecPrefix: String {
    let prefix = String((codec ?? "").lowercased().prefix(4))
    return prefix.isEmpty ? "avc1" : prefix
  }
}
