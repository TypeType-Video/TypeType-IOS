import Foundation

// What the chat column shows: the newest messages and where the connection stands.
// The server numbers the messages of each connection from chat-1 and starts a new one with the chat's recent
// backlog, so a new connection starts the list over (the web client does the same): ids only identify a message
// within one connection, and keeping the old list would show the backlog twice.
struct LiveChatBuffer: Equatable {
  enum Status: Equatable {
    case connecting
    case connected
    case ended
    case unavailable
  }

  // Android TV keeps 30: a column of a TV shows fewer lines than that.
  static let keptMessages = 30
  static let rememberedIDs = 400

  private(set) var messages: [LiveChatMessage] = []
  private(set) var status: Status = .connecting
  private var remembered: [String] = []
  private var rememberedSet: Set<String> = []

  mutating func apply(_ events: [LiveChatEvent]) {
    for event in events {
      switch event {
      case .connected:
        messages.removeAll()
        remembered.removeAll()
        rememberedSet.removeAll()
        if status == .connecting { status = .connected }
      case let .message(message):
        append(message)
      case .ended:
        status = .ended
      case .unavailable:
        status = .unavailable
      }
    }
    if messages.count > Self.keptMessages { messages.removeFirst(messages.count - Self.keptMessages) }
  }

  private mutating func append(_ message: LiveChatMessage) {
    guard rememberedSet.insert(message.id).inserted else { return }
    remembered.append(message.id)
    if remembered.count > Self.rememberedIDs {
      rememberedSet.remove(remembered.removeFirst())
    }
    messages.append(message)
  }
}

enum LiveChatSupport {
  // The server only serves the chat of YouTube lives.
  static func supports(videoURL: String) -> Bool {
    guard let host = URL(string: videoURL)?.host?.lowercased() else { return false }
    return host == "youtube.com" || host.hasSuffix(".youtube.com") || host == "youtu.be"
  }
}
