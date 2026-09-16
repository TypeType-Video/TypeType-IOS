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

struct LiveSubscriptionGroup: Codable, Equatable, Hashable, Identifiable {
  let id: String
  let name: String
  let channelCount: Int
  let createdAt: Int64
  let updatedAt: Int64
}

enum LiveSubscriptionFilter: Equatable, Hashable {
  case all
  case ungrouped
  case group(id: String, name: String)
}
