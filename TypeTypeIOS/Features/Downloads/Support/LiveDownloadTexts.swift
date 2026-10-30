import Foundation

enum LiveDownloadTexts {
  static func duration(_ seconds: Int64?) -> String? {
    guard let seconds, seconds > 0 else { return nil }
    let style: Duration.TimeFormatStyle.Pattern = seconds >= 3600 ? .hourMinuteSecond : .minuteSecond
    return Duration.seconds(seconds).formatted(.time(pattern: style))
  }

  static func size(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
  }

  static func summary(_ record: LiveManagedDownload) -> String {
    var parts = [mode(record.options.mode)]
    if let height = record.job.resolved?.height ?? record.options.height {
      parts.append("\(height)p")
    }
    if let total = record.job.totalBytes, total > 0 {
      parts.append(size(total))
    }
    return parts.joined(separator: " · ")
  }

  static func transfer(_ record: LiveManagedDownload) -> String {
    guard record.state == .downloading else { return record.state.title }
    var parts: [String] = []
    if let percent = record.job.progressPercent {
      parts.append(Double(percent).formatted(.number) + " %")
    }
    if let speed = record.job.speedBytesPerSecond, speed > 0 {
      parts.append(String(localized: "\(size(speed))/s"))
    }
    if let eta = record.job.etaSeconds, eta > 0 {
      let left = Duration.seconds(eta).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 1))
      parts.append(String(localized: "\(left) left"))
    }
    return parts.isEmpty ? record.state.title : parts.joined(separator: " · ")
  }

  static func mode(_ raw: String) -> String {
    switch raw {
    case LiveDownloadMode.audio.rawValue: String(localized: "Audio")
    case LiveDownloadMode.thumbnail.rawValue: String(localized: "Thumbnail")
    default: String(localized: "Video")
    }
  }
}
