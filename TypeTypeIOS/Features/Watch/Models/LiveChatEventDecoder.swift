import Foundation

enum LiveChatEventDecoder {
  // nil for an event that carries nothing to show: an unknown name, a message without text, a payload that is
  // not a message. Only an `error` event throws, so the caller reconnects.
  static func decode(_ event: LiveSSEEvent) throws -> LiveChatEvent? {
    switch event.name {
    case "message": return message(from: event.data).map(LiveChatEvent.message)
    case "ended": return .ended
    case "error": throw LiveChatStreamError.server(errorText(event.data))
    default: return nil
    }
  }

  static func message(from data: String) -> LiveChatMessage? {
    guard let payload = try? JSONDecoder().decode(Payload.self, from: Data(data.utf8)) else { return nil }
    let text = clean(payload.text ?? "")
    guard !text.isEmpty else { return nil }
    let id = payload.id.flatMap { $0.isEmpty ? nil : $0 } ?? UUID().uuidString
    return LiveChatMessage(
      id: id,
      author: clean(payload.authorName ?? ""),
      text: text,
      moderator: payload.moderator ?? false
    )
  }

  // One line of text: U+FFFC (YouTube's placeholder for an inline emoji, drawn as a boxed "OBJ"), zero-width
  // spaces and the byte order mark are dropped, runs of whitespace and line breaks become one space. The
  // zero-width joiner stays: it holds emoji like a family together.
  static func clean(_ raw: String) -> String {
    let dropped: Set<Character> = ["\u{FFFC}", "\u{200B}", "\u{2060}", "\u{FEFF}"]
    let kept = raw.filter { !dropped.contains($0) }
    return kept.split(whereSeparator: \.isWhitespace).joined(separator: " ")
  }

  private struct Payload: Decodable {
    let id: String?
    let text: String?
    let authorName: String?
    let moderator: Bool?
  }

  private struct ErrorPayload: Decodable {
    let error: String?
  }

  private static func errorText(_ data: String) -> String {
    if let payload = try? JSONDecoder().decode(ErrorPayload.self, from: Data(data.utf8)),
      let message = payload.error, !message.isEmpty {
      return message
    }
    return String(data.prefix(200))
  }
}
