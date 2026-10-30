import Foundation

@MainActor
enum LiveNotificationTexts {
  static func message(for toast: LiveNotificationSettingsViewModel.Toast) -> String {
    let limit = LiveNotificationSettingsViewModel.pollingQueryBudget
    switch toast {
    case .limitReached:
      return String(localized: "Limit of \(limit) channels reached. Turn one off to turn on another.")
    case let .turnedOn(count, leftOff) where leftOff > 0:
      return String(localized: "\(count) channels turned on.") + " "
        + String(localized: "\(leftOff) channels stayed off: the limit is reached.")
    case let .turnedOn(count, _):
      return String(localized: "\(count) channels turned on.")
    case let .turnedOff(count):
      return String(localized: "\(count) channels turned off.")
    }
  }

  static func note(for limit: LiveNotificationSettingsViewModel.Limit) -> String? {
    let budget = LiveNotificationSettingsViewModel.pollingQueryBudget
    switch limit {
    case .comfortable:
      return nil
    case let .close(remaining):
      return String(localized: "\(remaining) channels left before the limit of \(budget).")
    case .reached:
      return String(localized: "Limit of \(budget) channels reached. Turn one off to turn on another.")
    }
  }
}
