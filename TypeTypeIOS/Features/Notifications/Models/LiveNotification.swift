import Foundation

struct LiveNotification: Decodable, Equatable, Identifiable {
  let serverID: String?
  var read: Bool
  let type: String
  let title: String
  let createdAt: Int64
  let publishedAt: Int64
  let channelURL: String
  let channelName: String
  let channelAvatarURL: String
  let video: LiveVideoItem

  var id: String {
    serverID ?? compositeID
  }

  var deepLinkURL: URL? {
    var components = URLComponents()
    components.scheme = "typetype"
    components.host = "watch"
    components.queryItems = [
      URLQueryItem(name: "v", value: video.canonicalID),
    ]
    return components.url
  }

  private var compositeID: String {
    "\(type):\(channelURL):\(video.canonicalID):\(createdAt)"
  }

  private enum CodingKeys: String, CodingKey {
    case serverID = "id"
    case read
    case type, title, createdAt, publishedAt
    case channelURL = "channelUrl"
    case channelName
    case channelAvatarURL = "channelAvatarUrl"
    case video
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    serverID = try values.decodeIfPresent(String.self, forKey: .serverID)
    read = try values.decodeIfPresent(Bool.self, forKey: .read) ?? false
    type = try values.decode(String.self, forKey: .type)
    title = try values.decode(String.self, forKey: .title)
    createdAt = try values.decode(Int64.self, forKey: .createdAt)
    publishedAt = try values.decode(Int64.self, forKey: .publishedAt)
    channelURL = try values.decode(String.self, forKey: .channelURL)
    channelName = try values.decode(String.self, forKey: .channelName)
    channelAvatarURL = try values.decode(
      String.self,
      forKey: .channelAvatarURL
    )
    video = try values.decode(LiveVideoItem.self, forKey: .video)
  }
}

struct LiveNotificationsPage: Decodable, Equatable {
  let items: [LiveNotification]
  let unreadCount: Int
  let nextPage: Int?

  private enum CodingKeys: String, CodingKey {
    case items, unreadCount
    case nextPage = "nextpage"
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    items = try values.decode([LiveNotification].self, forKey: .items)
    unreadCount = try values.decode(Int.self, forKey: .unreadCount)
    if let page = try? values.decodeIfPresent(Int.self, forKey: .nextPage) {
      nextPage = page
    } else {
      nextPage = Int(
        try values.decodeIfPresent(String.self, forKey: .nextPage) ?? ""
      )
    }
  }
}

struct LiveUnreadNotifications: Decodable, Equatable {
  let unreadCount: Int
}

struct LiveNotificationsReadResult: Decodable, Equatable {
  let readAt: Int64
  let unreadCount: Int
}
