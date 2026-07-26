import Foundation

enum LiveHistoryFilter: Equatable {
  case all
  case today
  case week
  case month
  case date(Date)

  var title: String {
    switch self {
    case .all:
      return "All dates"
    case .today:
      return "Today"
    case .week:
      return "This week"
    case .month:
      return "This month"
    case let .date(date):
      return date.formatted(date: .abbreviated, time: .omitted)
    }
  }

  func range(
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> (from: Int64, to: Int64)? {
    let start: Date
    let end: Date
    switch self {
    case .all:
      return nil
    case .today:
      start = calendar.startOfDay(for: now)
      end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
    case .week:
      let interval = calendar.dateInterval(of: .weekOfYear, for: now)
      start = interval?.start ?? calendar.startOfDay(for: now)
      end = interval?.end ?? now
    case .month:
      let interval = calendar.dateInterval(of: .month, for: now)
      start = interval?.start ?? calendar.startOfDay(for: now)
      end = interval?.end ?? now
    case let .date(date):
      start = calendar.startOfDay(for: date)
      end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
    }
    return (
      Int64(start.timeIntervalSince1970 * 1_000),
      Int64(end.timeIntervalSince1970 * 1_000)
    )
  }
}
