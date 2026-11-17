import Foundation

enum LiveTwitchRoute: Hashable {
  case channel(String)
  case game(slug: String, name: String)
  case tag(String)
}

enum LiveTwitchFormat {
  static func count(_ value: Int) -> String {
    Int64(value).formatted(.number.notation(.compactName))
  }

  static func clock(_ seconds: TimeInterval) -> String {
    LiveVideoMetadataFormatter.duration(Int64(max(seconds, 0).rounded()))
  }

  static func date(_ iso: String) -> Date? {
    ISO8601DateFormatter().date(from: iso)
  }

  static func videoDetail(views: Int, created: String) -> String {
    let watched = String(localized: "\(count(views)) views")
    guard let date = date(created) else { return watched }
    return watched + " · " + date.formatted(.relative(presentation: .named))
  }
}
