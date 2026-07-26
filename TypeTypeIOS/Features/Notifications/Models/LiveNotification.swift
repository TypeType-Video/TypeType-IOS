import Foundation

struct LiveNotification: Decodable, Equatable, Identifiable {
  let type: String
  let title: String
  let createdAt: Int64
  let publishedAt: Int64
  let channelURL: String
  let channelName: String
  let channelAvatarURL: String
  let video: LiveVideoItem

  var id: String {
    "\(type):\(channelURL):\(video.canonicalID):\(createdAt)"
  }

  private enum CodingKeys: String, CodingKey {
    case type, title, createdAt, publishedAt
    case channelURL = "channelUrl"
    case channelName
    case channelAvatarURL = "channelAvatarUrl"
    case video
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
