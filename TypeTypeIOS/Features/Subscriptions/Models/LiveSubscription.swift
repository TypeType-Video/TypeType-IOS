struct LiveSubscription: Codable, Equatable, Hashable, Identifiable {
  let channelURL: String
  let name: String
  let avatarURL: String
  let subscribedAt: Int64

  var id: String {
    channelURL
  }

  private enum CodingKeys: String, CodingKey {
    case channelURL = "channelUrl"
    case name
    case avatarURL = "avatarUrl"
    case subscribedAt
  }
}

struct LiveSubscriptionPayload: Encodable {
  let channelURL: String
  let name: String
  let avatarURL: String

  private enum CodingKeys: String, CodingKey {
    case channelURL = "channelUrl"
    case name
    case avatarURL = "avatarUrl"
  }
}
