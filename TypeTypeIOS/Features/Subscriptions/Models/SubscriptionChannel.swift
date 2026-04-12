import Foundation

struct SubscriptionChannel: Decodable, Identifiable {
  let channelUrl: String
  let name: String
  let avatarUrl: String
  let subscribedAt: Int64

  var id: String { channelUrl }
}
