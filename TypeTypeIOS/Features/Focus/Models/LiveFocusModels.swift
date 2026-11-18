import Foundation

struct LiveFocusSettings: Decodable, Equatable {
  enum Schedule: String, Codable, CaseIterable {
    case always
    case weekdays
  }

  enum Status: Equatable {
    case off
    case on(day: Int, total: Int, percent: Int)
    case leaving(hours: Int)
  }

  static let transitionChoices = [30, 60, 90]
  static let archiveChoices = [3, 7, 14, 30]

  let enabled: Bool
  let entertainmentGroupID: String?
  let studyGroupID: String?
  let schedule: Schedule
  let timezone: String?
  let transitionDays: Int
  let archiveDays: Int
  let startedAt: Int64?
  let disableAt: Int64?
  let entertainmentShare: Double

  private enum CodingKeys: String, CodingKey {
    case enabled, schedule, timezone, transitionDays, archiveDays, startedAt, disableAt, entertainmentShare
    case entertainmentGroupID = "entertainmentGroupId"
    case studyGroupID = "studyGroupId"
  }

  func status(now: Date) -> Status {
    guard enabled else { return .off }
    let nowMS = Int64(now.timeIntervalSince1970 * 1000)
    if let disableAt {
      return .leaving(hours: max(1, Int((Double(disableAt - nowMS) / 3_600_000).rounded(.up))))
    }
    let started = startedAt ?? nowMS
    let day = min(transitionDays, max(1, Int((nowMS - started) / 86_400_000) + 1))
    return .on(day: day, total: transitionDays, percent: Int((entertainmentShare * 100).rounded()))
  }

  static func choices(_ base: [Int], current: Int) -> [Int] {
    base.contains(current) ? base : (base + [current]).sorted()
  }
}

struct LiveFocusRequest: Encodable, Equatable {
  var enabled: Bool
  var entertainmentGroupID: String?
  var studyGroupID: String?
  var schedule: LiveFocusSettings.Schedule?
  var timezone: String?
  var transitionDays: Int?
  var archiveDays: Int?

  private enum CodingKeys: String, CodingKey {
    case enabled, schedule, timezone, transitionDays, archiveDays
    case entertainmentGroupID = "entertainmentGroupId"
    case studyGroupID = "studyGroupId"
  }
}
