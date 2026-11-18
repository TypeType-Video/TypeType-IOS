import Foundation

struct LiveTwitchEmoteImage: Hashable {
  let name: String
  let url: URL?
}

enum LiveTwitchChatPart: Hashable {
  case text(String)
  case emote(LiveTwitchEmoteImage, overlays: [LiveTwitchEmoteImage])
  case link(String, URL)
  case mention(String, isSelf: Bool)
}

// Same rules as the web client: Twitch emote ranges count Unicode scalars, third-party emotes match whole words, and
// a zero-width emote sits on top of the emote before it.
enum LiveTwitchChatParts {
  static func twitchEmote(id: String, name: String) -> LiveTwitchEmoteImage {
    let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
    return LiveTwitchEmoteImage(name: name, url: URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(encoded)/default/dark/2.0"))
  }

  static func parts(
    text: String,
    native: [LiveTwitchChatEmote] = [],
    emotes: [String: LiveTwitchThirdPartyEmote] = [:],
    selfLogin: String = ""
  ) -> [LiveTwitchChatPart] {
    let scalars = Array(text.unicodeScalars)
    let ranges = native.filter { $0.start >= 0 && $0.end < scalars.count && $0.start <= $0.end }.sorted { $0.start < $1.start }
    var parts: [LiveTwitchChatPart] = []
    var cursor = 0
    let me = selfLogin.lowercased()
    for range in ranges where range.start >= cursor {
      segment(String(String.UnicodeScalarView(scalars[cursor..<range.start])), into: &parts, emotes: emotes, me: me)
      let name = String(String.UnicodeScalarView(scalars[range.start...range.end]))
      parts.append(.emote(twitchEmote(id: range.id, name: name), overlays: []))
      cursor = range.end + 1
    }
    segment(String(String.UnicodeScalarView(scalars[cursor...])), into: &parts, emotes: emotes, me: me)
    return parts
  }

  static func mentionsSelf(_ parts: [LiveTwitchChatPart]) -> Bool {
    parts.contains { if case .mention(_, true) = $0 { true } else { false } }
  }

  private static func segment(_ text: String, into parts: inout [LiveTwitchChatPart], emotes: [String: LiveTwitchThirdPartyEmote], me: String) {
    var word = ""
    for character in text {
      if character.isWhitespace {
        if !word.isEmpty { push(word: word, into: &parts, emotes: emotes, me: me); word = "" }
        appendText(String(character), to: &parts)
      } else {
        word.append(character)
      }
    }
    if !word.isEmpty { push(word: word, into: &parts, emotes: emotes, me: me) }
  }

  private static func push(word: String, into parts: inout [LiveTwitchChatPart], emotes: [String: LiveTwitchThirdPartyEmote], me: String) {
    if let emote = emotes[word] {
      let image = LiveTwitchEmoteImage(name: emote.name, url: URL(string: emote.url2x ?? emote.url))
      if emote.zeroWidth == true, let index = lastEmoteIndex(parts), case let .emote(base, overlays) = parts[index] {
        if index < parts.count - 1 { parts.removeLast() }
        parts[index] = .emote(base, overlays: overlays + [image])
      } else {
        parts.append(.emote(image, overlays: []))
      }
      return
    }
    if word.hasPrefix("@"), word.count > 1 {
      let name = String(word.dropFirst()).trimmingCharacters(in: trailing)
      parts.append(.mention("@" + name, isSelf: name.lowercased() == me))
      appendText(String(word.dropFirst(name.count + 1)), to: &parts)
      return
    }
    let trimmed = word.trimmingCharacters(in: trailing)
    if let url = linkURL(trimmed) {
      parts.append(.link(trimmed, url))
      appendText(String(word.dropFirst(trimmed.count)), to: &parts)
      return
    }
    appendText(word, to: &parts)
  }

  private static let trailing = CharacterSet(charactersIn: "),.!?:;'\"]")

  private static let bareDomains: Set<String> = [
    "com", "net", "org", "info", "biz", "xyz", "io", "co", "app", "dev", "me", "tv", "gg", "ly", "to", "sh", "so", "ai",
    "fm", "am", "video", "live", "stream", "games", "game", "fun", "art", "blog", "club", "online", "site", "store", "shop",
    "tech", "link", "page", "news", "wiki", "social", "media", "be", "fr", "de", "uk", "es", "it", "nl", "eu", "ru", "jp",
    "cn", "kr", "br", "ca", "us", "au", "ch", "at", "se", "no", "dk", "fi", "pl", "pt", "cz", "ie", "in", "mx", "ar",
  ]

  static func linkURL(_ word: String) -> URL? {
    let schemed = word.lowercased().hasPrefix("http://") || word.lowercased().hasPrefix("https://")
    guard let url = URL(string: schemed ? word : "https://" + word), let host = url.host?.lowercased(),
      ["http", "https"].contains(url.scheme?.lowercased() ?? ""), host.contains("."),
      host.split(separator: ".").allSatisfy({ !$0.isEmpty })
    else { return nil }
    let domain = host.split(separator: ".").last.map(String.init) ?? ""
    guard domain.count >= 2, domain.allSatisfy(\.isLetter) else { return nil }
    if !schemed, !host.hasPrefix("www."), !bareDomains.contains(domain) { return nil }
    return url
  }

  private static func appendText(_ text: String, to parts: inout [LiveTwitchChatPart]) {
    guard !text.isEmpty else { return }
    if case let .text(previous)? = parts.last {
      parts[parts.count - 1] = .text(previous + text)
    } else {
      parts.append(.text(text))
    }
  }

  private static func lastEmoteIndex(_ parts: [LiveTwitchChatPart]) -> Int? {
    guard let last = parts.indices.last else { return nil }
    if case .emote = parts[last] { return last }
    if case let .text(space) = parts[last], space.trimmingCharacters(in: .whitespaces).isEmpty, last > 0,
      case .emote = parts[last - 1] {
      return last - 1
    }
    return nil
  }
}
