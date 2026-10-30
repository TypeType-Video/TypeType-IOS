import SwiftUI

enum LiveAccentColor: String, Codable, CaseIterable, Identifiable {
  case red, blue, yellow, green, purple, violet, monochrome, system, custom

  var id: String { rawValue }

  var title: String {
    switch self {
    case .red: return "Red"
    case .blue: return "Blue"
    case .yellow: return "Yellow"
    case .green: return "Green"
    case .purple: return "Purple"
    case .violet: return "Violet"
    case .monochrome: return "Monochrome"
    case .system: return "System"
    case .custom: return "Custom"
    }
  }

  var color: Color {
    switch self {
    case .red: return Color(red: 1, green: 0.30, blue: 0.32)
    case .blue: return .blue
    case .yellow: return .yellow
    case .green: return .green
    case .purple: return .purple
    case .violet: return .indigo
    case .monochrome: return .primary
    case .system: return .accentColor
    case .custom: return .accentColor
    }
  }
}

enum LiveAppearanceTheme: String, Codable, CaseIterable, Identifiable {
  case typetype, snow, nord, cream, forest, plum
  var id: String { rawValue }

  // Stores may still hold the removed `dynamic` theme: it maps to Snow.
  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    switch raw {
    case "dynamic":
      self = .snow
    default:
      self = LiveAppearanceTheme(rawValue: raw) ?? .typetype
    }
  }

  var title: String {
    switch self {
    case .typetype: return "TypeType"
    case .snow: return "Snow"
    case .nord: return "Nord"
    case .cream: return "Cream"
    case .forest: return "Forest"
    case .plum: return "Plum"
    }
  }
}

enum LiveAppearanceFont: String, Codable, CaseIterable, Identifiable {
  case system, expressive
  var id: String { rawValue }
  var title: String { self == .system ? "System" : "Expressive" }
}

enum LiveAppearanceMotion: String, Codable, CaseIterable, Identifiable {
  case full, subtle, off
  var id: String { rawValue }

  var title: String {
    switch self {
    case .full: return "Full"
    case .subtle: return "Subtle"
    case .off: return "Off"
    }
  }

  var duration: TimeInterval? {
    switch self {
    case .full: return 0.28
    case .subtle: return 0.16
    case .off: return 0
    }
  }
}
