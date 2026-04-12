import Foundation

struct NotificationItem: Decodable, Identifiable {
  let type: String
  let title: String
  let createdAt: Int64
  let publishedAt: Int64
  let channelUrl: String
  let channelName: String
  let channelAvatarUrl: String
  let video: HomeVideoItem

  var id: String { "\(video.id)-\(createdAt)" }
}
