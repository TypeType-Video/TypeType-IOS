import Foundation

struct LiveVideoItem: Decodable, Hashable, Identifiable {
  let id: String
  let title: String
  let url: String
  let thumbnailURL: String
  let uploaderName: String
  let uploaderURL: String
  let uploaderAvatarURL: String
  let duration: Int64
  let viewCount: Int64
  let uploadDate: String
  let uploaded: Int64
  let streamType: String
  let isShortFormContent: Bool
  let uploaderVerified: Bool
  let shortDescription: String?
  let publishedAt: Int64?
  let isLive: Bool
  let isPostLive: Bool
  let isLiveContent: Bool
  let requiresMembership: Bool

  var canonicalID: String {
    url.isEmpty ? id : url
  }

  var thumbnail: URL? {
    URL(string: thumbnailURL)
  }

  var uploaderAvatar: URL? {
    URL(string: uploaderAvatarURL)
  }

  var publicationDate: Date? {
    guard let value = publishedAt ?? (uploaded > 0 ? uploaded : nil) else {
      return nil
    }
    let seconds = value > 10_000_000_000
      ? TimeInterval(value) / 1_000
      : TimeInterval(value)
    return Date(timeIntervalSince1970: seconds)
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case title
    case url
    case thumbnailURL = "thumbnailUrl"
    case uploaderName
    case uploaderURL = "uploaderUrl"
    case uploaderAvatarURL = "uploaderAvatarUrl"
    case duration
    case viewCount
    case uploadDate
    case uploaded
    case streamType
    case isShortFormContent
    case uploaderVerified
    case shortDescription
    case publishedAt
    case isLive
    case isPostLive
    case isLiveContent
    case requiresMembership
  }
}
