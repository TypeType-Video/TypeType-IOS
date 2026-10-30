import Foundation

enum LiveNotificationTexts {
  static func message(for toast: LiveNotificationSettingsViewModel.Toast) -> String {
    switch toast {
    case let .turnedOn(count):
      String(localized: "\(count) channels turned on.")
    case let .turnedOff(count):
      String(localized: "\(count) channels turned off.")
    }
  }
}
