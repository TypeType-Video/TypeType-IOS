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

  private static func preservingAnchorDestinations(
    in value: String
  ) -> String {
    guard let expression = try? NSRegularExpression(
      pattern: #"<a\b[^>]*href\s*=\s*["']([^"']+)["'][^>]*>(.*?)</a>"#,
      options: [.caseInsensitive, .dotMatchesLineSeparators]
    ) else {
      return value
    }

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

  static func decodingHTMLEntities(in value: String) -> String {
    let document = value.replacingOccurrences(of: "\n", with: "<br>")
    guard let data = document.data(using: .utf8),
      let attributed = try? NSAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue,
        ],
        documentAttributes: nil
      )
    else {
      return value
    }
    return attributed.string
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
