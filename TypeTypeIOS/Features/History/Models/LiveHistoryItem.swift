import Foundation

struct LiveHistoryItem: Decodable, Equatable, Identifiable {
  let id: String
  let url: String
  let title: String
  let thumbnail: String
  let channelName: String
  let channelURL: String
  let channelAvatar: String
  let duration: Int64
  let progress: Int64
  let watchedAt: Int64
  let publishedAt: Int64?
  let viewCount: Int64

  init(
    id: String,
    url: String,
    title: String,
    thumbnail: String = "",
    channelName: String = "",
    channelURL: String = "",
    channelAvatar: String = "",
    duration: Int64 = 0,
    progress: Int64 = 0,
    watchedAt: Int64 = 0,
    publishedAt: Int64? = nil,
    viewCount: Int64 = 0
  ) {
    self.id = id
    self.url = url
    self.title = title
    self.thumbnail = thumbnail
    self.channelName = channelName
    self.channelURL = channelURL
    self.channelAvatar = channelAvatar
    self.duration = duration
    self.progress = progress
    self.watchedAt = watchedAt
    self.publishedAt = publishedAt
    self.viewCount = viewCount
  }

  var thumbnailURL: URL? { URL(string: thumbnail) }
  var avatarURL: URL? { URL(string: channelAvatar) }

  var watchedDate: Date {
    let seconds = watchedAt > 10_000_000_000
      ? TimeInterval(watchedAt) / 1_000
      : TimeInterval(watchedAt)
    return Date(timeIntervalSince1970: seconds)
  }

  var progressFraction: Double {
    guard duration > 0 else { return 0 }
    return min(max(Double(progress) / Double(duration), 0), 1)
  }

  var video: LiveVideoItem {
    LiveVideoItem(
      id: url,
      title: title,
      url: url,
      thumbnailURL: thumbnail,
      uploaderName: channelName,
      uploaderURL: channelURL,
      uploaderAvatarURL: channelAvatar,
      duration: duration,
      viewCount: viewCount,
      uploadDate: "",
      uploaded: publishedAt ?? -1,
      streamType: "video",
      isShortFormContent: false,
      uploaderVerified: false,
      shortDescription: nil,
      publishedAt: publishedAt,
      isLive: false,
      isPostLive: false,
      isLiveContent: false,
      requiresMembership: false
    )
  }

  private enum CodingKeys: String, CodingKey {
    case id, url, title, thumbnail, channelName
    case channelURL = "channelUrl"
    case channelAvatar, duration, progress, watchedAt
    case publishedAt, viewCount
  }

  init(from decoder: Decoder) throws {
    // Tolerant on purpose: legacy rows (imported history, pre-app entries)
    // omit or null fields the modern payloads always carry. A single strict
    // field killed the whole page decode, which is why older history never
    // appeared.
    let values = try decoder.container(keyedBy: CodingKeys.self)
    // Every field is read through `try?`: legacy rows carry wrong types and
    // omitted keys alike (decodeIfPresent still throws on type mismatch).
    url = (try? values.decode(String.self, forKey: .url))
      ?? (try? values.decodeIfPresent(String.self, forKey: .url))
      ?? ""
    guard !url.isEmpty else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "History item without a url"
        )
      )
    }
    id = (try? values.decodeIfPresent(String.self, forKey: .id)) ?? url
    title = (try? values.decodeIfPresent(String.self, forKey: .title)) ?? ""
    thumbnail = (try? values.decodeIfPresent(String.self, forKey: .thumbnail))
      ?? ""
    channelName = (try? values.decodeIfPresent(
      String.self, forKey: .channelName
    )) ?? ""
    channelURL = (try? values.decodeIfPresent(
      String.self, forKey: .channelURL
    )) ?? ""
    channelAvatar = (try? values.decodeIfPresent(
      String.self, forKey: .channelAvatar
    )) ?? ""
    duration = (try? values.decodeIfPresent(Int64.self, forKey: .duration))
      ?? -1
    progress = (try? values.decodeIfPresent(Int64.self, forKey: .progress))
      ?? 0
    watchedAt = (try? values.decodeIfPresent(Int64.self, forKey: .watchedAt))
      ?? 0
    publishedAt = (try? values.decodeIfPresent(
      Int64.self, forKey: .publishedAt
    ))
    viewCount = (try? values.decodeIfPresent(Int64.self, forKey: .viewCount))
      ?? 0
  }
}
