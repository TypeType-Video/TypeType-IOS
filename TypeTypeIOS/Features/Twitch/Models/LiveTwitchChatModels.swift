import Foundation

struct LiveTwitchChatEmote: Decodable, Hashable {
  let id: String
  let start: Int
  let end: Int
}

struct LiveTwitchRoomState: Decodable, Hashable {
  let followersOnly: Int
  let slow: Int
  let emoteOnly: Bool
  let subsOnly: Bool
  let uniqueChat: Bool

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    followersOnly = try values.decodeIfPresent(Int.self, forKey: .followersOnly) ?? -1
    slow = try values.decodeIfPresent(Int.self, forKey: .slow) ?? 0
    emoteOnly = try values.decodeIfPresent(Bool.self, forKey: .emoteOnly) ?? false
    subsOnly = try values.decodeIfPresent(Bool.self, forKey: .subsOnly) ?? false
    uniqueChat = try values.decodeIfPresent(Bool.self, forKey: .uniqueChat) ?? false
  }

  private enum CodingKeys: String, CodingKey {
    case followersOnly, slow, emoteOnly, subsOnly, uniqueChat
  }
}

struct LiveTwitchChatEvent: Decodable, Hashable, Identifiable {
  enum Kind: String, Decodable {
    case message, notice, delete, clear, room
  }

  let kind: Kind
  let eventID: String?
  let login: String?
  let displayName: String?
  let color: String?
  let text: String?
  let system: String?
  let emotes: [LiveTwitchChatEmote]
  let badges: [String]
  let time: String
  let action: Bool
  let targetID: String?
  let room: LiveTwitchRoomState?
  var deleted = false

  var id: String { eventID ?? "\(time)|\(login ?? "")|\(text ?? system ?? "")" }
  var author: String { displayName?.isEmpty == false ? displayName ?? "" : login ?? "" }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    kind = (try? values.decode(Kind.self, forKey: .type)) ?? .notice
    eventID = try values.decodeIfPresent(String.self, forKey: .id)
    login = try values.decodeIfPresent(String.self, forKey: .login)
    displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
    color = try values.decodeIfPresent(String.self, forKey: .color)
    text = try values.decodeIfPresent(String.self, forKey: .text)
    system = try values.decodeIfPresent(String.self, forKey: .system)
    emotes = try values.decodeIfPresent([LiveTwitchChatEmote].self, forKey: .emotes) ?? []
    badges = try values.decodeIfPresent([String].self, forKey: .badges) ?? []
    time = try values.decodeIfPresent(String.self, forKey: .time) ?? ""
    action = try values.decodeIfPresent(Bool.self, forKey: .action) ?? false
    targetID = try values.decodeIfPresent(String.self, forKey: .targetId)
    room = try values.decodeIfPresent(LiveTwitchRoomState.self, forKey: .room)
  }

  private enum CodingKeys: String, CodingKey {
    case type, id, login, displayName, color, text, system, emotes, badges, time, action, targetId, room
  }
}

struct LiveTwitchThirdPartyEmote: Decodable, Hashable {
  let name: String
  let url: String
  let url2x: String?
  let provider: String?
  let animated: Bool?
  let zeroWidth: Bool?
}

struct LiveTwitchChatBadge: Decodable, Hashable {
  let title: String
  let url: String
  let url2x: String?
}

struct LiveTwitchChatAssets: Decodable {
  let channelID: String?
  let badges: [String: LiveTwitchChatBadge]
  let emotes: [LiveTwitchThirdPartyEmote]

  static let empty = LiveTwitchChatAssets(channelID: nil, badges: [:], emotes: [])

  init(channelID: String?, badges: [String: LiveTwitchChatBadge], emotes: [LiveTwitchThirdPartyEmote]) {
    self.channelID = channelID
    self.badges = badges
    self.emotes = emotes
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    channelID = try values.decodeIfPresent(String.self, forKey: .channelId)
    badges = try values.decodeIfPresent([String: LiveTwitchChatBadge].self, forKey: .badges) ?? [:]
    emotes = try values.decodeIfPresent([LiveTwitchThirdPartyEmote].self, forKey: .emotes) ?? []
  }

  // The channel's own badges and emotes win over the global ones that share a key or a name.
  func merged(over global: LiveTwitchChatAssets) -> LiveTwitchChatAssets {
    let names = Set(emotes.map(\.name))
    return LiveTwitchChatAssets(
      channelID: channelID ?? global.channelID,
      badges: global.badges.merging(badges) { _, channel in channel },
      emotes: emotes + global.emotes.filter { !names.contains($0.name) }
    )
  }

  private enum CodingKeys: String, CodingKey {
    case channelId, badges, emotes
  }
}

struct LiveTwitchPollChoice: Decodable, Hashable, Identifiable {
  let id: String
  let title: String
  let votes: Int
}

struct LiveTwitchPoll: Decodable, Hashable {
  let id: String
  let title: String
  let status: String
  let durationSeconds: Int
  let remainingMs: Int
  let votes: Int
  let choices: [LiveTwitchPollChoice]

  var isActive: Bool { status == "ACTIVE" }
}

struct LiveTwitchPinnedMessage: Decodable, Hashable {
  let id: String
  let text: String
  let login: String
  let displayName: String
  let pinnedBy: String?

  var author: String { displayName.isEmpty ? login : displayName }
}

struct LiveTwitchChatHighlights: Decodable {
  let poll: LiveTwitchPoll?
  let pinned: LiveTwitchPinnedMessage?
}

struct LiveTwitchVideoComment: Decodable, Hashable, Identifiable {
  let id: String
  let offset: Double
  let login: String?
  let displayName: String?
  let color: String?
  let text: String
  let emotes: [LiveTwitchChatEmote]?
  let badges: [String]?

  var author: String { displayName?.isEmpty == false ? displayName ?? "" : login ?? "" }
}
