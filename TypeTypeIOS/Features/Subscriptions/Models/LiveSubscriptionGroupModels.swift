import Foundation

struct LiveSubscriptionGroupMembership: Codable, Equatable, Identifiable {
  let channelURL: String
  let name: String
  let avatarURL: String
  let subscribedAt: Int64
  let groupIDs: [String]

  var id: String {
    channelURL
  }

  private enum CodingKeys: String, CodingKey {
    case channelURL = "channelUrl"
    case name
    case avatarURL = "avatarUrl"
    case subscribedAt
    case groupIDs = "groupIds"
  }
}

struct LiveSubscriptionGroupNamePayload: Encodable, Equatable {
  let name: String
}

struct LiveSubscriptionGroupChannelsPayload: Encodable, Equatable {
  let channelURLs: [String]

  private enum CodingKeys: String, CodingKey {
    case channelURLs = "channelUrls"
  }
}
