import Foundation

struct LivePlaylistVideo: Decodable, Equatable, Hashable, Identifiable {
  let id: String
  let url: String
  let title: String
  let thumbnail: String
  let duration: Int64
  let position: Int
  let channelName: String
  let channelURL: String
  let channelAvatar: String
  let viewCount: Int64
  let addedAt: Int64
  let publishedAt: Int64
  let watchPosition: Int64
  let watched: Bool
  let progressUpdatedAt: Int64

  init(
    id: String = "",
    url: String,
    title: String,
    thumbnail: String,
    duration: Int64,
    position: Int = 0,
    channelName: String = "",
    channelURL: String = "",
    channelAvatar: String = "",
    viewCount: Int64 = 0,
    addedAt: Int64 = 0,
    publishedAt: Int64 = -1,
    watchPosition: Int64 = 0,
    watched: Bool = false,
    progressUpdatedAt: Int64 = 0
  ) {
    self.id = id
    self.url = url
    self.title = title
    self.thumbnail = thumbnail
    self.duration = duration
    self.position = position
    self.channelName = channelName
    self.channelURL = channelURL
    self.channelAvatar = channelAvatar
    self.viewCount = viewCount
    self.addedAt = addedAt
    self.publishedAt = publishedAt
    self.watchPosition = watchPosition
    self.watched = watched
    self.progressUpdatedAt = progressUpdatedAt
  }

  var video: LiveVideoItem {
    LiveVideoItem(
      id: id.isEmpty ? url : id,
      title: title,
      url: url,
      thumbnailURL: thumbnail,
      uploaderName: channelName,
      uploaderURL: channelURL,
      uploaderAvatarURL: channelAvatar,
      duration: duration,
      viewCount: viewCount,
      uploadDate: "",
      uploaded: publishedAt,
      streamType: "video",
      isShortFormContent: false,
      uploaderVerified: false,
      shortDescription: nil,
      publishedAt: publishedAt >= 0 ? publishedAt : nil,
      isLive: false,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }

  private enum CodingKeys: String, CodingKey {
    case id, url, title, thumbnail, thumbnailURL
    case duration, position, channelName, uploaderName
    case channelURL = "channelUrl"
    case uploaderURL = "uploaderUrl"
    case channelAvatar, channelAvatarURL, uploaderAvatarURL
    case viewCount, addedAt, publishedAt, watchPosition
    case watched, progressUpdatedAt
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    url = try values.decode(String.self, forKey: .url)
    id = values.string(.id, default: url)
    title = values.string(.title)
    thumbnail = values.firstString([.thumbnail, .thumbnailURL])
    duration = values.int64(.duration)
    position = values.integer(.position)
    channelName = values.firstString([.channelName, .uploaderName])
    channelURL = values.firstString([.channelURL, .uploaderURL])
    channelAvatar = values.firstString([
      .channelAvatar,
      .channelAvatarURL,
      .uploaderAvatarURL,
    ])
    viewCount = values.int64(.viewCount)
    addedAt = values.int64(.addedAt)
    publishedAt = values.int64(.publishedAt, default: -1)
    watchPosition = values.int64(.watchPosition)
    watched = values.boolean(.watched)
    progressUpdatedAt = values.int64(.progressUpdatedAt)
  }
}

private extension KeyedDecodingContainer {
  func string(_ key: Key, default value: String = "") -> String {
    (try? decodeIfPresent(String.self, forKey: key)) ?? value
  }

  func firstString(_ keys: [Key]) -> String {
    for key in keys {
      if let value = try? decode(String.self, forKey: key),
        !value.isEmpty {
        return value
      }
    }
    return ""
  }

  func int64(_ key: Key, default value: Int64 = 0) -> Int64 {
    (try? decodeIfPresent(Int64.self, forKey: key)) ?? value
  }

  func integer(_ key: Key) -> Int {
    (try? decodeIfPresent(Int.self, forKey: key)) ?? 0
  }

  func boolean(_ key: Key) -> Bool {
    (try? decodeIfPresent(Bool.self, forKey: key)) ?? false
  }
}
