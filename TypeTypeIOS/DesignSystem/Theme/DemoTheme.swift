import SwiftUI
import UIKit

enum DemoTheme {
  static var accent = Color(red: 1, green: 0.30, blue: 0.32)
  static var appearanceMode = LiveAppearanceMode.system
  static var appearanceAmoled = false
  static var appearanceTheme = LiveAppearanceTheme.typetype
  static var appearancePersonality = LiveAppearancePersonality.classic
  static var mangaPaper = LiveMangaPaper.day

  static var background: Color {
    themed(.systemBackground)
  }

  static var groupedBackground: Color {
    themed(.secondarySystemGroupedBackground)
  }

  static var surface: Color {
    themed(.secondarySystemBackground)
  }

  static var groupedSurface: Color {
    themed(.tertiarySystemGroupedBackground)
  }

  static var elevatedSurface: Color {
    themed(.tertiarySystemBackground)
  }

  static let separator = Color(uiColor: .separator)

  static func updateAccent(_ preference: LiveAccentColor) {
    accent = preference.color
  }

  static func update(
    preferences: LiveAppPreferences,
    colorScheme: ColorScheme? = nil
  ) {
    accent = preferences.accentColor.color
    appearanceMode = preferences.appearanceMode
    appearanceAmoled = preferences.appearanceAmoled
    appearanceTheme = preferences.appearanceTheme
    appearancePersonality = preferences.appearancePersonality
    mangaPaper = preferences.mangaPaper
  }

  static func applyUIKitAppearance(
    _ preferences: LiveAppPreferences
  ) {
    let isDark = preferences.appearanceMode == .dark
      || (preferences.appearanceMode == .system
        && UITraitCollection.current.userInterfaceStyle == .dark)
      || preferences.appearanceAmoled
    let backgroundColor = themeUIColor(base: .systemBackground, isDark: isDark)
    let surfaceColor = themeUIColor(
      base: .secondarySystemBackground,
      isDark: isDark
    )

    UITableView.appearance().backgroundColor = backgroundColor
    UICollectionView.appearance().backgroundColor = backgroundColor
    UITableViewCell.appearance().backgroundColor = .clear
    UICollectionViewCell.appearance().backgroundColor = .clear
    // Transparent, not surfaceColor: painting this white put a square
    // block behind every section header, clashing with the rounded cards.
    UITableViewHeaderFooterView.appearance().backgroundColor = .clear
  }

  private static func themeUIColor(
    base: UIColor,
    isDark: Bool
  ) -> UIColor {
    if appearanceAmoled { return .black }
    if appearancePersonality == .manga {
      return mangaColor(isDark: isDark)
    }
    switch appearanceTheme {
    case .typetype, .dynamic:
      return base
    case .nord:
      return isDark
        ? UIColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1)
        : UIColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1)
    case .cream:
      return isDark
        ? UIColor(red: 0.15, green: 0.10, blue: 0.07, alpha: 1)
        : UIColor(red: 1, green: 0.97, blue: 0.93, alpha: 1)
    case .forest:
      return isDark
        ? UIColor(red: 0.04, green: 0.12, blue: 0.08, alpha: 1)
        : UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1)
    case .plum:
      return isDark
        ? UIColor(red: 0.11, green: 0.06, blue: 0.16, alpha: 1)
        : UIColor(red: 0.98, green: 0.96, blue: 1, alpha: 1)
    }
  }

  private static func themed(_ base: UIColor) -> Color {
    let isDark = appearanceMode == .dark
      || UITraitCollection.current.userInterfaceStyle == .dark
      || appearanceAmoled
    if appearancePersonality == .manga,
      appearanceTheme == .typetype || appearanceTheme == .dynamic {
      return Color(uiColor: mangaColor(isDark: isDark))
    }
    return Color(uiColor: resolvedUIColor(base, isDark: isDark))
  }

  private static func resolvedUIColor(
    _ base: UIColor,
    isDark: Bool
  ) -> UIColor {
    if appearanceAmoled { return .black }
    switch appearanceTheme {
    case .typetype, .dynamic:
      return base
    case .nord:
      return isDark
        ? UIColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1)
        : UIColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1)
    case .cream:
      return isDark
        ? UIColor(red: 0.15, green: 0.10, blue: 0.07, alpha: 1)
        : UIColor(red: 1, green: 0.97, blue: 0.93, alpha: 1)
    case .forest:
      return isDark
        ? UIColor(red: 0.04, green: 0.12, blue: 0.08, alpha: 1)
        : UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1)
    case .plum:
      return isDark
        ? UIColor(red: 0.11, green: 0.06, blue: 0.16, alpha: 1)
        : UIColor(red: 0.98, green: 0.96, blue: 1, alpha: 1)
    }
  }

  private static func mangaColor(isDark: Bool) -> UIColor {
    switch mangaPaper {
    case .day:
      return isDark
        ? UIColor(red: 0.13, green: 0.12, blue: 0.10, alpha: 1)
        : UIColor(red: 1, green: 0.99, blue: 0.96, alpha: 1)
    case .night:
      return .black
    case .nord:
      return UIColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1)
    }
  }
}
