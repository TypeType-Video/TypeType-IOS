import Foundation

struct LiveFavoriteItem: Decodable, Equatable {
  let videoURL: String
  let favoritedAt: Int64
  let title: String
  let thumbnail: String
  let duration: Int64
  let channelName: String
  let channelURL: String
  let channelAvatar: String
  let viewCount: Int64
  let publishedAt: Int64

  init(
    videoURL: String,
    favoritedAt: Int64 = 0,
    title: String = "",
    thumbnail: String = "",
    duration: Int64 = 0,
    channelName: String = "",
    channelURL: String = "",
    channelAvatar: String = "",
    viewCount: Int64 = 0,
    publishedAt: Int64 = -1
  ) {
    self.videoURL = videoURL
    self.favoritedAt = favoritedAt
    self.title = title
    self.thumbnail = thumbnail
    self.duration = duration
    self.channelName = channelName
    self.channelURL = channelURL
    self.channelAvatar = channelAvatar
    self.viewCount = viewCount
    self.publishedAt = publishedAt
  }

  var libraryVideo: LiveLibraryVideo {
    LiveLibraryVideo(
      url: videoURL,
      title: title,
      thumbnail: thumbnail,
      duration: duration,
      channelName: channelName,
      channelURL: channelURL,
      channelAvatar: channelAvatar,
      viewCount: viewCount,
      publishedAt: publishedAt,
      savedAt: favoritedAt
    )
  }

  private enum CodingKeys: String, CodingKey {
    case videoURL = "videoUrl"
    case favoritedAt, title, thumbnail, duration, channelName
    case channelURL = "channelUrl"
    case channelAvatar, viewCount, publishedAt
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    videoURL = try values.decode(String.self, forKey: .videoURL)
    favoritedAt = values.int64(.favoritedAt)
    title = values.string(.title)
    thumbnail = values.string(.thumbnail)
    duration = values.int64(.duration)
    channelName = values.string(.channelName)
    channelURL = values.string(.channelURL)
    channelAvatar = values.string(.channelAvatar)
    viewCount = values.int64(.viewCount)
    publishedAt = values.int64(.publishedAt, default: -1)
  }
}

struct LiveWatchLaterItem: Codable, Equatable {
  let url: String
  let title: String
  let thumbnail: String
  let duration: Int64
  let addedAt: Int64
  let channelName: String
  let channelURL: String
  let channelAvatar: String
  let viewCount: Int64
  let publishedAt: Int64

  init(
    url: String,
    title: String,
    thumbnail: String = "",
    duration: Int64 = 0,
    addedAt: Int64 = 0,
    channelName: String = "",
    channelURL: String = "",
    channelAvatar: String = "",
    viewCount: Int64 = 0,
    publishedAt: Int64 = -1
  ) {
    self.url = url
    self.title = title
    self.thumbnail = thumbnail
    self.duration = duration
    self.addedAt = addedAt
    self.channelName = channelName
    self.channelURL = channelURL
    self.channelAvatar = channelAvatar
    self.viewCount = viewCount
    self.publishedAt = publishedAt
  }

  var libraryVideo: LiveLibraryVideo {
    LiveLibraryVideo(
      url: url,
      title: title,
      thumbnail: thumbnail,
      duration: duration,
      channelName: channelName,
      channelURL: channelURL,
      channelAvatar: channelAvatar,
      viewCount: viewCount,
      publishedAt: publishedAt,
      savedAt: addedAt
    )
  }

  private enum CodingKeys: String, CodingKey {
    case url, title, thumbnail, duration, addedAt, channelName
    case channelURL = "channelUrl"
    case channelAvatar, viewCount, publishedAt
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    url = try values.decode(String.self, forKey: .url)
    title = values.string(.title)
    thumbnail = values.string(.thumbnail)
    duration = values.int64(.duration)
    addedAt = values.int64(.addedAt)
    channelName = values.string(.channelName)
    channelURL = values.string(.channelURL)
    channelAvatar = values.string(.channelAvatar)
    viewCount = values.int64(.viewCount)
    publishedAt = values.int64(.publishedAt, default: -1)
  }

  init(video: LiveVideoItem) {
    url = video.url
    title = video.title
    thumbnail = video.thumbnailURL
    duration = video.duration
    addedAt = 0
    channelName = video.uploaderName
    channelURL = video.uploaderURL
    channelAvatar = video.uploaderAvatarURL
    viewCount = video.viewCount
    publishedAt = video.publishedAt ?? video.uploaded
  }

  func encode(to encoder: Encoder) throws {
    var values = encoder.container(keyedBy: CodingKeys.self)
    try values.encode(url, forKey: .url)
    try values.encode(title, forKey: .title)
    try values.encode(thumbnail, forKey: .thumbnail)
    try values.encode(duration, forKey: .duration)
    try values.encode(channelName, forKey: .channelName)
    try values.encode(channelURL, forKey: .channelURL)
    try values.encode(channelAvatar, forKey: .channelAvatar)
    try values.encode(viewCount, forKey: .viewCount)
    try values.encode(publishedAt, forKey: .publishedAt)
  }
}

private extension KeyedDecodingContainer {
  func string(_ key: Key) -> String {
    (try? decodeIfPresent(String.self, forKey: key)) ?? ""
  }

  func int64(_ key: Key, default defaultValue: Int64 = 0) -> Int64 {
    (try? decodeIfPresent(Int64.self, forKey: key)) ?? defaultValue
  }
}
