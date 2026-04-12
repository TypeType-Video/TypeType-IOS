import Foundation

struct NotificationsPage: Decodable {
  let items: [NotificationItem]
  let unreadCount: Int
  let nextPage: String?

  private enum CodingKeys: String, CodingKey {
    case items
    case unreadCount
    case nextPage = "nextpage"
  }
}
