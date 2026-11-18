import Foundation

struct LiveTwitchChatState: Equatable {
  static let maximumMessages = 200

  private(set) var messages: [LiveTwitchChatEvent] = []
  private(set) var room: LiveTwitchRoomState?

  mutating func apply(_ event: LiveTwitchChatEvent) {
    switch event.kind {
    case .room:
      if let state = event.room { room = state }
    case .delete:
      markDeleted { $0.eventID != nil && $0.eventID == event.targetID }
    case .clear:
      if let login = event.login {
        markDeleted { $0.login == login }
      } else {
        markDeleted { _ in true }
      }
    case .message, .notice:
      if let id = event.eventID, messages.contains(where: { $0.eventID == id }) { return }
      if messages.count >= Self.maximumMessages { messages.removeFirst(messages.count - Self.maximumMessages + 1) }
      messages.append(event)
    }
  }

  private mutating func markDeleted(_ match: (LiveTwitchChatEvent) -> Bool) {
    for index in messages.indices where match(messages[index]) {
      messages[index].deleted = true
    }
  }
}

struct LiveTwitchChatRefusal: Equatable {
  enum Reason: Equatable {
    case followers, subscribers, emotesOnly, slow, duplicate, verify, banned
    case other(String?)
  }

  let reason: Reason

  init(code: String?) {
    let value = (code ?? "").uppercased()
    if value.contains("FOLLOWER") {
      reason = .followers
    } else if value.contains("SUB") {
      reason = .subscribers
    } else if value.contains("EMOTE") {
      reason = .emotesOnly
    } else if value.contains("SLOW") {
      reason = .slow
    } else if value.contains("DUPLICATE") || value.contains("R9K") {
      reason = .duplicate
    } else if value.contains("VERIF") {
      reason = .verify
    } else if value.contains("BAN") || value.contains("SUSPEND") || value.contains("TIMEOUT") {
      reason = .banned
    } else {
      reason = .other(value.isEmpty ? nil : value)
    }
  }

  var suggestsFollowing: Bool { reason == .followers }

  var message: String {
    switch reason {
    case .followers: String(localized: "This chat is for followers. Follow the channel to write.")
    case .subscribers: String(localized: "This chat is for subscribers.")
    case .emotesOnly: String(localized: "Only emotes are allowed right now.")
    case .slow: String(localized: "Slow mode is on: wait before sending another message.")
    case .duplicate: String(localized: "Twitch refused a message identical to a recent one.")
    case .verify: String(localized: "This chat needs a verified email or phone on your Twitch account.")
    case .banned: String(localized: "You can't chat in this channel right now.")
    case let .other(code?): String(localized: "Twitch refused this message.") + " (\(code))"
    case .other(nil): String(localized: "Twitch refused this message.")
    }
  }
}
