import Foundation
import SwiftUI

struct InteractiveText: View {
  let text: String
  let font: Font
  let lineLimit: Int?
  let onSeekTimestamp: (Double) -> Void
  let onOpenURL: (URL) -> Void

  var body: some View {
    Text(RichTextParser.attributed(text))
      .font(font)
      .lineLimit(lineLimit)
      .fixedSize(horizontal: false, vertical: true)
      .environment(
        \.openURL,
        OpenURLAction { url in
          if let seconds = RichTextParser.seekSeconds(from: url) {
            onSeekTimestamp(seconds)
          } else {
            onOpenURL(url)
          }
          return .handled
        }
      )
  }
}

enum RichTextParser {
  private struct Token {
    let range: NSRange
    let url: URL
  }

  static func attributed(_ text: String) -> AttributedString {
    let source = text as NSString
    let tokens = detectedTokens(in: text)
    var result = AttributedString()
    var cursor = 0

    for token in tokens {
      if token.range.location > cursor {
        let range = NSRange(
          location: cursor,
          length: token.range.location - cursor
        )
        result.append(AttributedString(source.substring(with: range)))
      }
      var linked = AttributedString(source.substring(with: token.range))
      linked.link = token.url
      linked.foregroundColor = .accentColor
      linked.underlineStyle = .single
      result.append(linked)
      cursor = NSMaxRange(token.range)
    }

    if cursor < source.length {
      result.append(
        AttributedString(
          source.substring(
            with: NSRange(location: cursor, length: source.length - cursor)
          )
        )
      )
    }
    return result
  }

  static func seekSeconds(from url: URL) -> Double? {
    guard url.scheme == "typetype", url.host == "seek",
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let value = components.queryItems?.first(where: { $0.name == "seconds" })?.value
    else {
      return nil
    }
    return Double(value)
  }

  private static func detectedTokens(in text: String) -> [Token] {
    let fullRange = NSRange(location: 0, length: (text as NSString).length)
    var tokens = detectedLinks(in: text, range: fullRange)
    guard let regex = try? NSRegularExpression(
      pattern: #"(?<![0-9])(?:(\d{1,2}):)?([0-5]?[0-9]):([0-5][0-9])(?![0-9])"#
    ) else {
      return tokens
    }

    for match in regex.matches(in: text, range: fullRange) {
      guard !tokens.contains(where: { NSIntersectionRange($0.range, match.range).length > 0 }),
        let seconds = timestampSeconds(in: text, match: match),
        let url = seekURL(seconds: seconds)
      else {
        continue
      }
      tokens.append(Token(range: match.range, url: url))
    }
    return tokens.sorted { $0.range.location < $1.range.location }
  }

  private static func detectedLinks(in text: String, range: NSRange) -> [Token] {
    guard let detector = try? NSDataDetector(
      types: NSTextCheckingResult.CheckingType.link.rawValue
    ) else {
      return []
    }
    return detector.matches(in: text, range: range).compactMap { match in
      guard let url = match.url else { return nil }
      return Token(range: match.range, url: url)
    }
  }

  private static func timestampSeconds(
    in text: String,
    match: NSTextCheckingResult
  ) -> Double? {
    let source = text as NSString
    let hours = number(in: source, range: match.range(at: 1)) ?? 0
    guard let minutes = number(in: source, range: match.range(at: 2)),
      let seconds = number(in: source, range: match.range(at: 3))
    else {
      return nil
    }
    return (hours * 3_600) + (minutes * 60) + seconds
  }

  private static func number(in text: NSString, range: NSRange) -> Double? {
    guard range.location != NSNotFound else { return nil }
    return Double(text.substring(with: range))
  }

  private static func seekURL(seconds: Double) -> URL? {
    var components = URLComponents()
    components.scheme = "typetype"
    components.host = "seek"
    components.queryItems = [
      URLQueryItem(name: "seconds", value: String(seconds)),
    ]
    return components.url
  }
}
