import Foundation

enum LiveTTML {
  static func cues(in data: Data) -> [LiveSubtitleCue] {
    let reader = LiveTTMLReader()
    let parser = XMLParser(data: data)
    parser.delegate = reader
    parser.shouldProcessNamespaces = true
    guard parser.parse() else { return [] }
    return reader.cues.sorted { $0.start < $1.start }
  }

  static func time(_ value: String, tickRate: Double) -> TimeInterval? {
    let value = value.trimmingCharacters(in: .whitespaces)
    if value.contains(":") {
      return LiveWebVTT.timestamp(value)
    }
    let units: [(suffix: String, scale: Double)] = [
      ("ms", 0.001), ("h", 3_600), ("m", 60), ("s", 1), ("t", 1 / tickRate)
    ]
    for unit in units where value.hasSuffix(unit.suffix) {
      guard let amount = Double(value.dropLast(unit.suffix.count)), amount >= 0 else { return nil }
      return amount * unit.scale
    }
    return nil
  }
}

private final class LiveTTMLReader: NSObject, XMLParserDelegate {
  private(set) var cues: [LiveSubtitleCue] = []
  private var tickRate = 1.0
  private var timing: (start: TimeInterval, end: TimeInterval)?
  private var text = ""

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName: String?,
    attributes: [String: String]
  ) {
    switch elementName {
    case "tt":
      let rate = attributes.first { $0.key.split(separator: ":").last == "tickRate" }.flatMap { Double($0.value) }
      if let rate, rate > 0 { tickRate = rate }
    case "p":
      text = ""
      timing = cueTiming(attributes)
    case "br":
      text += "\n"
    default:
      break
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    guard timing != nil else { return }
    text += string
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName: String?
  ) {
    guard elementName == "p", let timing else { return }
    self.timing = nil
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { line in
      line.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    let cueText = lines.filter { !$0.isEmpty }.joined(separator: "\n")
    guard !cueText.isEmpty else { return }
    cues.append(LiveSubtitleCue(start: timing.start, end: timing.end, text: cueText))
  }

  private func cueTiming(_ attributes: [String: String]) -> (start: TimeInterval, end: TimeInterval)? {
    guard let start = attributes["begin"].flatMap({ LiveTTML.time($0, tickRate: tickRate) }) else { return nil }
    let end = attributes["end"].flatMap { LiveTTML.time($0, tickRate: tickRate) }
      ?? attributes["dur"].flatMap { LiveTTML.time($0, tickRate: tickRate) }.map { start + $0 }
    guard let end, end > start else { return nil }
    return (start, end)
  }
}
