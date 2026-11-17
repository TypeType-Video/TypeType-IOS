import Foundation

struct LiveTwitchLive: Decodable {
  let channel: LiveTwitchChannel
  let hlsURL: String
  let audioURL: String?

  private enum CodingKeys: String, CodingKey {
    case channel
    case hlsURL = "hlsUrl"
    case audioURL = "audioUrl"
  }
}

struct LiveTwitchVideoPlayback: Decodable {
  let video: LiveTwitchVideo
  let hlsURL: String
  let audioURL: String?

  private enum CodingKeys: String, CodingKey {
    case video
    case hlsURL = "hlsUrl"
    case audioURL = "audioUrl"
  }
}

struct LiveTwitchClipQuality: Decodable {
  let quality: String
  let frameRate: Double?
  let url: String
}

struct LiveTwitchClipPlayback: Decodable {
  let clip: LiveTwitchClip
  let qualities: [LiveTwitchClipQuality]
}

struct LiveTwitchChapter: Decodable {
  let start: Int
  let title: String
}

struct LiveTwitchMedia {
  let url: URL
  let audioURL: URL?
  var live: LiveTwitchStream? = nil
}

enum LiveTwitchPlaybackError: LocalizedError, Equatable {
  case offline
  case restricted

  var errorDescription: String? {
    switch self {
    case .offline: String(localized: "This channel is offline or this video no longer exists.")
    case .restricted: String(localized: "This content is restricted (subscribers only or not available in this region).")
    }
  }

  static func translating(_ error: Error) -> Error {
    guard case let .statusCode(status, _, _)? = error as? NetworkError else { return error }
    switch status {
    case 404: return LiveTwitchPlaybackError.offline
    case 403: return LiveTwitchPlaybackError.restricted
    default: return error
    }
  }
}
