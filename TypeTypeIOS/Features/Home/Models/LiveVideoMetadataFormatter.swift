import Foundation

enum LiveVideoMetadataFormatter {
  static func duration(_ seconds: Int64) -> String {
    guard seconds > 0 else { return "0:00" }
    let hours = seconds / 3_600
    let minutes = (seconds % 3_600) / 60
    let remainingSeconds = seconds % 60
    if hours > 0 {
      return String(
        format: "%lld:%02lld:%02lld",
        hours,
        minutes,
        remainingSeconds
      )
    }
    return String(
      format: "%lld:%02lld",
      minutes,
      remainingSeconds
    )
  }

  static func views(_ count: Int64) -> String {
    // The server sends -1 when the service does not report a view count.
    guard count >= 0 else { return "" }
    let value = count.formatted(
      .number.notation(.compactName)
    )
    return "\(value) views"
  }

  static func subscribers(_ count: Int64) -> String {
    compactCount(count) + " subscribers"
  }

  static func compactCount(_ count: Int64) -> String {
    count.formatted(.number.notation(.compactName))
  }

  // From the timestamp only: the upstream text can be in any locale.
  static func publication(_ video: LiveVideoItem) -> String {
    guard let date = video.publicationDate else {
      return ""
    }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: .now)
  }

  static func fullPublication(_ video: LiveVideoItem) -> String {
    guard let date = video.publicationDate else {
      return ""
    }
    return date.formatted(date: .long, time: .omitted)
  }
}
