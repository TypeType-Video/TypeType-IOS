import Foundation

struct WatchStream: Decodable {
  let id: String
  let title: String
  let uploaderName: String
  let uploaderUrl: String
  let uploaderAvatarUrl: String
  let thumbnailUrl: String
  let description: String
  let duration: Int64
  let viewCount: Int64
  let uploadDate: String
  let requiresMembership: Bool
  let streamType: String
  let isShortFormContent: Bool
  let startPosition: Int64
  let hlsURL: String
  let videoStreams: [WatchVideoStream]
  let audioStreams: [WatchAudioStream]
  let subtitles: [WatchSubtitle]
  let relatedStreams: [HomeVideoItem]

  var playbackURL: URL? {
    if hlsURL.hasPrefix("http"), let url = URL(string: hlsURL) {
      return url
    }
    if let fallback = videoStreams.first(where: { $0.url.hasPrefix("http") })?.url {
      return URL(string: fallback)
    }
    return nil
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case title
    case uploaderName
    case uploaderUrl
    case uploaderAvatarUrl
    case thumbnailUrl
    case description
    case duration
    case viewCount
    case uploadDate
    case requiresMembership
    case streamType
    case isShortFormContent
    case startPosition
    case hlsURL = "hlsUrl"
    case videoStreams
    case audioStreams
    case subtitles
    case relatedStreams
  }
}
