import Foundation

struct LiveTwitchAccountStatus: Decodable, Equatable {
  let linked: Bool
  let login: String?
  let displayName: String?
  let avatarURL: String?

  var name: String { displayName?.isEmpty == false ? displayName ?? "" : login ?? "" }

  private enum CodingKeys: String, CodingKey {
    case linked, login, displayName
    case avatarURL = "avatarUrl"
  }
}

struct LiveTwitchDeviceCode: Decodable, Equatable {
  let deviceCode: String
  let userCode: String
  let verificationURI: String
  let interval: Int
  let expiresIn: Int

  private enum CodingKeys: String, CodingKey {
    case deviceCode, userCode, interval, expiresIn
    case verificationURI = "verificationUri"
  }
}

struct LiveTwitchDevicePoll: Decodable, Equatable {
  enum Status: String, Decodable {
    case pending
    case slowDown = "slow_down"
    case ok
  }

  let status: Status
  let account: LiveTwitchAccountStatus?
}

struct LiveTwitchSubscription: Decodable, Hashable {
  let tier: String
  let prime: Bool
  let months: Int
  let streak: Int
}

struct LiveTwitchFollowState: Decodable, Hashable {
  let channelID: String
  let following: Bool
  let subscription: LiveTwitchSubscription?

  private enum CodingKeys: String, CodingKey {
    case following, subscription
    case channelID = "channelId"
  }
}

struct LiveTwitchUserEmote: Decodable, Hashable, Identifiable {
  let id: String
  let name: String
  let type: String
  let ownerID: String?

  private enum CodingKeys: String, CodingKey {
    case id, name, type
    case ownerID = "ownerId"
  }
}

struct LiveTwitchUserEmotes: Decodable {
  let channelID: String
  let emotes: [LiveTwitchUserEmote]

  private enum CodingKeys: String, CodingKey {
    case emotes
    case channelID = "channelId"
  }
}

enum LiveTwitchChatSendResult: Equatable {
  case sent
  case rejected(reason: String?)
  case failed
}

enum LiveTwitchVoteResult: Equatable {
  case counted
  case freeVoteSpent
  case failed
}
