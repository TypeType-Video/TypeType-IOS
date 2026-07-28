import Foundation

struct LivePlaybackVideoSource: Decodable, Hashable, Identifiable {
  let url: String
  let mimeType: String
  let resolution: String
  let bitrate: Int?
  let codec: String?
  let isVideoOnly: Bool
  let itag: Int
  let width: Int
  let height: Int
  let fps: Int
  let contentLength: Int64
  let initStart: Int64
  let initEnd: Int64
  let indexStart: Int64
  let indexEnd: Int64
  let deliveryMethod: String
  let manifestURL: String?

  var id: String { selectionID }
  var selectionID: String {
    [
      String(itag),
      codec ?? "",
      String(height),
      String(bitrate ?? 0),
      deliveryMethod,
    ].joined(separator: ":")
  }

  var displayName: String {
    if !resolution.isEmpty { return resolution }
    if height > 0 { return "\(height)p" }
    return "Automatic"
  }

  var isAppleH264: Bool {
    mimeType.lowercased().hasPrefix("video/mp4")
      && codec?.lowercased().hasPrefix("avc1") == true
  }

  var isSABR: Bool {
    deliveryMethod.caseInsensitiveCompare("sabr") == .orderedSame
  }

  var isAppleProviderVideo: Bool {
    guard mimeType.lowercased().hasPrefix("video/mp4") else {
      return false
    }
    if deliveryMethod.caseInsensitiveCompare("hls") == .orderedSame
      || isHLSPlaylist {
      return true
    }
    return codec?.lowercased().hasPrefix("avc1") == true
  }

  private var isHLSPlaylist: Bool {
    URL(string: url)?.pathExtension.caseInsensitiveCompare("m3u8")
      == .orderedSame
  }

  private enum CodingKeys: String, CodingKey {
    case url, mimeType, resolution, bitrate, codec, isVideoOnly
    case itag, width, height, fps, contentLength
    case initStart, initEnd, indexStart, indexEnd, deliveryMethod
    case manifestURL = "manifestUrl"
  }
}

struct LivePlaybackAudioSource: Decodable, Hashable, Identifiable {
  let url: String
  let mimeType: String
  let bitrate: Int?
  let codec: String?
  let quality: String?
  let itag: Int
  let audioTrackID: String?
  let audioTrackName: String?
  let audioLocale: String?
  let isOriginal: Bool
  let contentLength: Int64
  let initStart: Int64
  let initEnd: Int64
  let indexStart: Int64
  let indexEnd: Int64
  let deliveryMethod: String
  let manifestURL: String?

  var id: String {
    [
      String(itag),
      audioTrackID ?? "",
      audioLocale ?? "",
      String(bitrate ?? 0),
      deliveryMethod,
    ].joined(separator: ":")
  }

  var displayName: String {
    if let audioTrackName, !audioTrackName.isEmpty {
      return audioTrackName
    }
    if let audioLocale, !audioLocale.isEmpty {
      return Locale.current.localizedString(
        forIdentifier: audioLocale
      ) ?? audioLocale
    }
    return isOriginal ? "Original" : "Default"
  }

  var isAppleAAC: Bool {
    mimeType.lowercased().hasPrefix("audio/mp4")
      && codec?.lowercased().hasPrefix("mp4a") == true
  }

  var isSABR: Bool {
    deliveryMethod.caseInsensitiveCompare("sabr") == .orderedSame
  }

  var isAppleProviderAudio: Bool {
    guard mimeType.lowercased().hasPrefix("audio/mp4") else {
      return false
    }
    if deliveryMethod.caseInsensitiveCompare("hls") == .orderedSame
      || isHLSPlaylist {
      return true
    }
    return codec?.lowercased().hasPrefix("mp4a") == true
      || codec?.lowercased() == "aac"
  }

  private var isHLSPlaylist: Bool {
    URL(string: url)?.pathExtension.caseInsensitiveCompare("m3u8")
      == .orderedSame
  }

  private enum CodingKeys: String, CodingKey {
    case url, mimeType, bitrate, codec, quality, itag
    case audioTrackName, audioLocale, isOriginal, contentLength
    case initStart, initEnd, indexStart, indexEnd, deliveryMethod
    case audioTrackID = "audioTrackId"
    case manifestURL = "manifestUrl"
  }
}
