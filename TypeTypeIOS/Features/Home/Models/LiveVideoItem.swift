import Foundation

struct LiveVideoItem: Codable, Hashable, Identifiable {
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

  // A single null or missing field in a row must not fail the page decode:
  // playlist and channel responses carry deleted or members-only entries
  // with holes, and one bad row used to take the whole list down.

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
    title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL) ?? ""
    uploaderName = try container.decodeIfPresent(String.self, forKey: .uploaderName) ?? ""
    uploaderURL = try container.decodeIfPresent(String.self, forKey: .uploaderURL) ?? ""
    uploaderAvatarURL = try container.decodeIfPresent(String.self, forKey: .uploaderAvatarURL) ?? ""
    duration = try container.decodeIfPresent(Int64.self, forKey: .duration) ?? 0
    viewCount = try container.decodeIfPresent(Int64.self, forKey: .viewCount) ?? 0
    uploadDate = try container.decodeIfPresent(String.self, forKey: .uploadDate) ?? ""
    uploaded = try container.decodeIfPresent(Int64.self, forKey: .uploaded) ?? 0
    streamType = try container.decodeIfPresent(String.self, forKey: .streamType) ?? ""
    isShortFormContent = try container.decodeIfPresent(Bool.self, forKey: .isShortFormContent) ?? false
    uploaderVerified = try container.decodeIfPresent(Bool.self, forKey: .uploaderVerified) ?? false
    shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription)
    publishedAt = try container.decodeIfPresent(Int64.self, forKey: .publishedAt)
    isLive = try container.decodeIfPresent(Bool.self, forKey: .isLive) ?? false
    isPostLive = try container.decodeIfPresent(Bool.self, forKey: .isPostLive) ?? false
    isLiveContent = try container.decodeIfPresent(Bool.self, forKey: .isLiveContent) ?? false
    requiresMembership = try container.decodeIfPresent(Bool.self, forKey: .requiresMembership) ?? false
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
