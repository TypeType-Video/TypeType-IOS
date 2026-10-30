import Foundation

enum LiveSubtitleDocument {
  static func cues(in data: Data, mimeType: String) -> [LiveSubtitleCue] {
    let text = String(decoding: data, as: UTF8.self)
    let type = mimeType.split(separator: ";").first?
      .trimmingCharacters(in: .whitespaces)
      .lowercased()
    let body = text.drop { $0 == "\u{FEFF}" || $0.isWhitespace }
    if type == "text/vtt" || body.hasPrefix("WEBVTT") {
      return LiveWebVTT.cues(in: text)
    }
    return LiveTTML.cues(in: data)
  }
}
