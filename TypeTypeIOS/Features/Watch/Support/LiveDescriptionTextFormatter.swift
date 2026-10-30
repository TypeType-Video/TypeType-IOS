import Foundation

enum LiveDescriptionTextFormatter {
  static func displayText(
    _ rawValue: String,
    sourceURL: String
  ) -> String {
    let trimmed = rawValue.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    guard isNicoNico(sourceURL), trimmed.contains("<") else {
      return trimmed
    }

    var value = preservingAnchorDestinations(in: trimmed)
    value = value.replacingOccurrences(
      of: #"(?i)<br\s*/?>"#,
      with: "\n",
      options: .regularExpression
    )
    value = value.replacingOccurrences(
      of: #"(?i)</(?:p|div|li|h[1-6])\s*>"#,
      with: "\n",
      options: .regularExpression
    )
    value = value.replacingOccurrences(
      of: #"(?s)<[^>]+>"#,
      with: "",
      options: .regularExpression
    )
    value = decodingHTMLEntities(in: value)
    value = value.replacingOccurrences(
      of: #"[ \t]+\n"#,
      with: "\n",
      options: .regularExpression
    )
    value = value.replacingOccurrences(
      of: #"\n{3,}"#,
      with: "\n\n",
      options: .regularExpression
    )
    return value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static let anchorPattern = try? NSRegularExpression(
    pattern: #"<a\b[^>]*href\s*=\s*["']([^"']+)["'][^>]*>(.*?)</a>"#,
    options: [.caseInsensitive, .dotMatchesLineSeparators]
  )

  private static func preservingAnchorDestinations(
    in value: String
  ) -> String {
    guard let expression = anchorPattern else { return value }

    let range = NSRange(value.startIndex..., in: value)
    let matches = expression.matches(in: value, range: range)
    var result = value
    for match in matches.reversed() {
      guard
        let matchRange = Range(match.range(at: 0), in: result),
        let destinationRange = Range(match.range(at: 1), in: result),
        let labelRange = Range(match.range(at: 2), in: result)
      else {
        continue
      }
      let destination = String(result[destinationRange])
      let label = String(result[labelRange]).replacingOccurrences(
        of: #"(?s)<[^>]+>"#,
        with: "",
        options: .regularExpression
      )
      let replacement = label.contains(destination)
        ? label
        : "\(label) (\(destination))"
      result.replaceSubrange(matchRange, with: replacement)
    }
    return result
  }

  private static let namedEntities: [String: String] = [
    "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}",
    "hellip": "…", "mdash": "—", "ndash": "–", "lsquo": "‘", "rsquo": "’",
    "ldquo": "“", "rdquo": "”", "laquo": "«", "raquo": "»", "middot": "·",
    "bull": "•", "copy": "©", "reg": "®", "trade": "™", "times": "×", "yen": "¥",
  ]

  static func decodingHTMLEntities(in value: String) -> String {
    guard value.contains("&") else { return value }
    var result = ""
    result.reserveCapacity(value.count)
    var index = value.startIndex
    while index < value.endIndex {
      let character = value[index]
      guard character == "&",
        let end = value[index...].prefix(12).firstIndex(of: ";"),
        let decoded = decodedEntity(String(value[value.index(after: index)..<end]))
      else {
        result.append(character)
        index = value.index(after: index)
        continue
      }
      result.append(decoded)
      index = value.index(after: end)
    }
    return result
  }

  private static func decodedEntity(_ name: String) -> String? {
    if name.hasPrefix("#") {
      let digits = name.dropFirst()
      let scalarValue = digits.first == "x" || digits.first == "X"
        ? UInt32(digits.dropFirst(), radix: 16)
        : UInt32(digits)
      return scalarValue.flatMap(Unicode.Scalar.init).map { String(Character($0)) }
    }
    return namedEntities[name]
  }

  private static func isNicoNico(_ rawURL: String) -> Bool {
    guard let host = URL(string: rawURL)?.host?.lowercased() else {
      return false
    }
    return host == "nicovideo.jp"
      || host.hasSuffix(".nicovideo.jp")
      || host == "nico.ms"
  }
}
