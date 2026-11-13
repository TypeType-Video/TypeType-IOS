import Foundation

struct LiveChatMessage: Equatable, Identifiable, Sendable {
  let id: String
  let author: String
  let text: String
  let moderator: Bool
}

enum LiveChatEvent: Equatable, Sendable {
  // The stream is open; the first message may take a while on a quiet chat.
  case connected
  case message(LiveChatMessage)
  // The live is over, the server says so.
  case ended
  // The video has no chat, or the connection kept failing: stop asking.
  case unavailable
}

// The server reports a failure inside an open stream as an `error` event: the stream is dropped and retried.
enum LiveChatStreamError: Error, Equatable {
  case server(String)
}
