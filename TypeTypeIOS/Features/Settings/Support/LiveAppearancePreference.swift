import SwiftUI

enum LiveAppearanceMode: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  var id: String { rawValue }

  var title: String {
    switch self {
    case .system: return "System"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}

enum LiveAppearancePreference {
  static let storageKey = "typetype.appearance.mode"
  static let defaultRawValue = LiveAppearanceMode.system.rawValue

  static func mode(for rawValue: String) -> LiveAppearanceMode {
    LiveAppearanceMode(rawValue: rawValue) ?? .system
  }
}
