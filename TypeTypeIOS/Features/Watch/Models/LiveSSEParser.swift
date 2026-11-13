import Foundation

struct LiveSSEEvent: Equatable, Sendable {
  let name: String
  let data: String
}

// Server-sent events, fed one byte at a time. Lines are split on the newline byte before any UTF-8 is read, so a
// character cut between two network reads is never decoded half. Lines end with "\n" or "\r\n", as the server
// writes them; a blank line ends an event, a line starting with ":" is a comment (the server's keep-alive).
struct LiveSSEParser {
  private var line: [UInt8] = []
  private var name = "message"
  private var data: [String] = []

  mutating func feed(_ byte: UInt8) -> LiveSSEEvent? {
    guard byte == 0x0A else {
      line.append(byte)
      return nil
    }
    return endLine()
  }

  mutating func feed<Bytes: Sequence>(_ bytes: Bytes) -> [LiveSSEEvent] where Bytes.Element == UInt8 {
    var events: [LiveSSEEvent] = []
    for byte in bytes {
      if let event = feed(byte) { events.append(event) }
    }
    return events
  }

  // The stream ended: an event whose blank line never came is still delivered, as the web client does.
  mutating func finish() -> LiveSSEEvent? {
    if !line.isEmpty { _ = endLine() }
    return dispatch()
  }

  private mutating func endLine() -> LiveSSEEvent? {
    var bytes = line
    line.removeAll(keepingCapacity: true)
    if bytes.last == 0x0D { bytes.removeLast() }
    guard !bytes.isEmpty else { return dispatch() }
    guard bytes[0] != 0x3A else { return nil }
    let text = String(decoding: bytes, as: UTF8.self)
    let field: String
    var value = Substring("")
    if let colon = text.firstIndex(of: ":") {
      field = String(text[..<colon])
      value = text[text.index(after: colon)...]
      if value.first == " " { value = value.dropFirst() }
    } else {
      field = text
    }
    switch field {
    case "event": name = value.isEmpty ? "message" : String(value)
    case "data": data.append(String(value))
    default: break
    }
    return nil
  }

  private mutating func dispatch() -> LiveSSEEvent? {
    defer {
      name = "message"
      data.removeAll()
    }
    guard !data.isEmpty else { return nil }
    return LiveSSEEvent(name: name, data: data.joined(separator: "\n"))
  }
}
