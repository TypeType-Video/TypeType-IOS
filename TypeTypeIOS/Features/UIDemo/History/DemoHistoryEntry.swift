import Foundation

struct DemoHistoryEntry: Identifiable {
  enum Group: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case week = "Earlier this week"
  }

  let video: DemoVideo
  let watchedAt: String
  let group: Group

  var id: String { video.id }
}

enum DemoHistoryCatalog {
  static let entries = [
    DemoHistoryEntry(
      video: DemoMockCatalog.continueWatching[0],
      watchedAt: "Watched 18 minutes ago",
      group: .today
    ),
    DemoHistoryEntry(
      video: DemoMockCatalog.recommendations[0],
      watchedAt: "Watched 2 hours ago",
      group: .today
    ),
    DemoHistoryEntry(
      video: DemoMockCatalog.recommendations[1],
      watchedAt: "Watched 5 hours ago",
      group: .today
    ),
    DemoHistoryEntry(
      video: DemoMockCatalog.recommendations[2],
      watchedAt: "Watched yesterday at 21:14",
      group: .yesterday
    ),
    DemoHistoryEntry(
      video: DemoMockCatalog.recommendations[4],
      watchedAt: "Watched yesterday at 08:42",
      group: .yesterday
    ),
    DemoHistoryEntry(
      video: DemoMockCatalog.recommendations[5],
      watchedAt: "Watched Tuesday",
      group: .week
    ),
  ]
}
