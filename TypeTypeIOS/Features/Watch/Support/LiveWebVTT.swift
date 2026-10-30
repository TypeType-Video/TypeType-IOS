import Foundation

struct LiveSubtitleCue: Equatable {
  let start: TimeInterval
  let end: TimeInterval
  let text: String
}

enum LiveWebVTT {
  static func cues(in document: String) -> [LiveSubtitleCue] {
    let blocks = document
      .replacingOccurrences(of: "\r\n", with: "\n")
      .components(separatedBy: "\n\n")
    let cues = blocks.compactMap { block -> LiveSubtitleCue? in
      let lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
      guard let timingIndex = lines.firstIndex(where: { $0.contains("-->") }) else { return nil }
      let parts = lines[timingIndex].components(separatedBy: "-->")
      guard parts.count == 2,
        let start = timestamp(parts[0]),
        let end = timestamp(parts[1].split(separator: " ", omittingEmptySubsequences: true).first.map(String.init) ?? ""),
        end > start
      else {
        return nil
      }
      let text = lines[(timingIndex + 1)...]
        .map(plainText)
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
      return text.isEmpty ? nil : LiveSubtitleCue(start: start, end: end, text: text)
    }
    return cues.sorted { $0.start < $1.start }
  }

  static func cue(at time: TimeInterval, in cues: [LiveSubtitleCue]) -> LiveSubtitleCue? {
    var low = 0
    var high = cues.count
    while low < high {
      let middle = (low + high) / 2
      if cues[middle].start <= time { low = middle + 1 } else { high = middle }
    }
    var index = low - 1
    while index >= 0, index >= low - 4 {
      if cues[index].end > time { return cues[index] }
      index -= 1
    }
    return nil
  }

  static func timestamp(_ value: String) -> TimeInterval? {
    let fields = value.trimmingCharacters(in: .whitespaces).split(separator: ":")
    guard (2...3).contains(fields.count), let seconds = Double(fields[fields.count - 1]) else { return nil }
    let minutes = Double(fields[fields.count - 2]) ?? -1
    let hours = fields.count == 3 ? Double(fields[0]) ?? -1 : 0
    guard minutes >= 0, hours >= 0 else { return nil }
    return hours * 3_600 + minutes * 60 + seconds
  }

  private static func plainText(_ line: String) -> String {
    let untagged = line.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
    return LiveDescriptionTextFormatter.decodingHTMLEntities(in: untagged)
      .trimmingCharacters(in: .whitespaces)
  }
}
