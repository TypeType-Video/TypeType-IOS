import Foundation

struct LivePlaylist: Decodable, Equatable, Hashable, Identifiable {
  let id: String
  let name: String
  let description: String
  let videos: [LivePlaylistVideo]
  let videoCount: Int
  let createdAt: Int64

  init(
    id: String,
    name: String,
    description: String = "",
    videos: [LivePlaylistVideo] = [],
    videoCount: Int? = nil,
    createdAt: Int64 = 0
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.videos = videos
    self.videoCount = videoCount ?? videos.count
    self.createdAt = createdAt
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, description, videos, videoCount, createdAt
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    name = try values.decode(String.self, forKey: .name)
    description = try values.decodeIfPresent(
      String.self,
      forKey: .description
    ) ?? ""
    videos = try values.decodeIfPresent(
      [LivePlaylistVideo].self,
      forKey: .videos
    ) ?? []
    videoCount = try values.decodeIfPresent(
      Int.self,
      forKey: .videoCount
    ) ?? videos.count
    createdAt = try values.decodeIfPresent(
      Int64.self,
      forKey: .createdAt
    ) ?? 0
  }
}

struct LivePlaylistPayload: Encodable {
  let name: String
  let description: String
}

struct LivePlaylistReorderPayload: Encodable {
  let order: [String]
}

struct LivePlaylistVideoPayload: Encodable {
  let url: String
  let title: String
  let thumbnail: String
  let duration: Int64
  let channelName: String
  let channelURL: String
  let channelAvatar: String
  let viewCount: Int64

  init(video: LiveVideoItem) {
    url = video.url
    title = video.title
    thumbnail = video.thumbnailURL
    duration = video.duration
    channelName = video.uploaderName
    channelURL = video.uploaderURL
    channelAvatar = video.uploaderAvatarURL
    viewCount = video.viewCount
  }

  private enum CodingKeys: String, CodingKey {
    case url, title, thumbnail, duration, channelName
    case channelURL = "channelUrl"
    case channelAvatar, viewCount
  }
}
