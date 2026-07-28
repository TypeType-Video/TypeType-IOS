import Foundation

extension LivePlaybackHTTPServer {
  func providerMasterPlaylist() throws -> String {
    guard let providerPlayback = preparation.providerPlayback,
      case let .separateHLS(videoURL, audioURL) = providerPlayback
    else {
      throw LivePlaybackFailure.invalidPlaylist
    }
    let videoRoute = register(
      target: .upstream(videoURL),
      pathExtension: "m3u8"
    )
    let audioRoute = register(
      target: .upstream(audioURL),
      pathExtension: "m3u8"
    )
    guard
      let localVideoURL = localURL(
        routeID: videoRoute,
        extension: "m3u8"
      ),
      let localAudioURL = localURL(
        routeID: audioRoute,
        extension: "m3u8"
      )
    else {
      throw LivePlaybackFailure.localPlaybackUnavailable
    }

    var lines = [
      "#EXTM3U",
      "#EXT-X-VERSION:7",
      "#EXT-X-INDEPENDENT-SEGMENTS",
      providerAudioDeclaration(url: localAudioURL),
    ]
    lines.append(contentsOf: providerSubtitleDeclarations())

    var attributes = [
      "BANDWIDTH=\(providerBandwidth)",
      "AUDIO=\"provider-audio\"",
    ]
    let codecs = providerCodecs
    if !codecs.isEmpty {
      attributes.append("CODECS=\"\(codecs)\"")
    }
    if let resolution = providerResolution {
      attributes.append("RESOLUTION=\(resolution)")
    }
    if !preparation.subtitles.isEmpty {
      attributes.append("SUBTITLES=\"subs\"")
    }
    lines.append("#EXT-X-STREAM-INF:\(attributes.joined(separator: ","))")
    lines.append(localVideoURL.absoluteString)
    lines.append("")
    return lines.joined(separator: "\n")
  }

  private func providerAudioDeclaration(url: URL) -> String {
    let name = preparation.audio?.displayName ?? "Default"
    return
      "#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"provider-audio\","
      + "NAME=\"\(hlsQuoted(name))\",DEFAULT=YES,AUTOSELECT=YES,"
      + "URI=\"\(url.absoluteString)\""
  }

  private func providerSubtitleDeclarations() -> [String] {
    let defaultIndex = preferredSubtitleIndex
    return preparation.subtitles.indices.compactMap { index in
      let routeID = register(
        target: .subtitlePlaylist(index),
        pathExtension: "m3u8"
      )
      guard let url = localURL(
        routeID: routeID,
        extension: "m3u8"
      ) else {
        return nil
      }
      let subtitle = preparation.subtitles[index]
      return
        "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\","
        + "NAME=\"\(hlsQuoted(subtitle.displayName))\","
        + "LANGUAGE=\"\(hlsQuoted(subtitle.languageTag))\","
        + "AUTOSELECT=YES,DEFAULT=\(index == defaultIndex ? "YES" : "NO"),"
        + "FORCED=NO,URI=\"\(url.absoluteString)\""
    }
  }

  private var providerBandwidth: Int {
    let video = preparation.video?.bitrate ?? 1_500_000
    let rawAudio = preparation.audio?.bitrate ?? 128_000
    let audio = rawAudio < 10_000 ? rawAudio * 1_000 : rawAudio
    return max(video + audio, 256_000)
  }

  private var providerCodecs: String {
    [
      preparation.video?.codec,
      preparation.audio?.codec,
    ]
    .compactMap { value in
      guard let value, !value.isEmpty else { return nil }
      return value
    }
    .joined(separator: ",")
  }

  private var providerResolution: String? {
    guard let video = preparation.video,
      video.width > 0,
      video.height > 0
    else {
      return nil
    }
    return "\(video.width)x\(video.height)"
  }
}
