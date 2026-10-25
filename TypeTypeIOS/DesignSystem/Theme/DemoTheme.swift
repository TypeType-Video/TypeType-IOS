import SwiftUI
import UIKit

enum DemoTheme {
  static var accent = Color(red: 1, green: 0.30, blue: 0.32)
  static var appearanceMode = LiveAppearanceMode.system
  static var appearanceAmoled = false
  /// The environment colour scheme (system light/dark); used for the
  /// `.system` mode instead of UITraitCollection so system changes react.
  static var systemColorScheme: ColorScheme?
  static var appearanceTheme = LiveAppearanceTheme.typetype
  static var appearancePersonality = LiveAppearancePersonality.classic
  static var mangaPaper = LiveMangaPaper.day

  static var background: Color {
    themed(.systemBackground)
  }

  static var groupedBackground: Color {
    themed(.secondarySystemGroupedBackground)
  }

  /// The grey page colour behind grouped cards.
  static var pageBackground: Color {
    themed(.systemGroupedBackground)
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
    if let colorScheme {
      systemColorScheme = colorScheme
    }
    appearanceTheme = preferences.appearanceTheme
    appearancePersonality = preferences.appearancePersonality
    mangaPaper = preferences.mangaPaper
  }

  static func applyUIKitAppearance(
    _ preferences: LiveAppPreferences
  ) {
    let isDark = preferences.appearanceMode == .dark
      || (preferences.appearanceMode == .system
        && (systemColorScheme == .dark
          || (systemColorScheme == nil
            && UITraitCollection.current.userInterfaceStyle == .dark)))
    let backgroundColor = themeUIColor(base: .systemBackground, isDark: isDark)
    UITableView.appearance().backgroundColor = backgroundColor
    UICollectionView.appearance().backgroundColor = backgroundColor
    UITableViewCell.appearance().backgroundColor = .clear
    UICollectionViewCell.appearance().backgroundColor = .clear
    // Transparent, not a surface color: painting this white put a square
    // block behind every section header, clashing with the rounded cards.
    UITableViewHeaderFooterView.appearance().backgroundColor = .clear
    // iOS 27 paints header chrome through backgroundView (a blur material),
    // which backgroundColor alone does not replace.
    UITableViewHeaderFooterView.appearance().backgroundView = UIView()
  }

  private static func themeUIColor(
    base: UIColor,
    isDark: Bool
  ) -> UIColor {
    if appearanceAmoled, isDark { return .black }
    if appearancePersonality == .manga {
      return mangaColor(isDark: isDark)
    }
    switch appearanceTheme {
    case .typetype, .dynamic:
      // Resolve statically against our own mode: dynamic system colors
      // follow stale traits while the user switches modes and made the
      // appearance screen flicker between states.
      return base.resolvedColor(
        with: UITraitCollection(
          userInterfaceStyle: isDark ? .dark : .light
        )
      )
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
    let isDark: Bool
    switch appearanceMode {
    case .dark:
      isDark = true
    case .light:
      isDark = false
    case .system:
      if let systemColorScheme {
        isDark = systemColorScheme == .dark
      } else {
        isDark = UITraitCollection.current.userInterfaceStyle == .dark
      }
    }
    // Android semantics: AMOLED black forces the dark scheme (see
    // AppearanceColorSchemes.kt: `isDark || amoled`).
    // AMOLED only recolours an already-dark UI to pure black. Light mode
    // and System-in-light stay light no matter the switch.
    let darkMode = isDark
    if appearancePersonality == .manga,
      appearanceTheme == .typetype || appearanceTheme == .dynamic {
      return Color(uiColor: mangaColor(isDark: darkMode))
    }
    return Color(uiColor: resolvedUIColor(base, isDark: darkMode))
  }

  private static func resolvedUIColor(
    _ base: UIColor,
    isDark: Bool
  ) -> UIColor {
    if appearanceAmoled, isDark { return .black }
    switch appearanceTheme {
    case .typetype, .dynamic:
      return base.resolvedColor(
        with: UITraitCollection(
          userInterfaceStyle: isDark ? .dark : .light
        )
      )
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

/// Pill button in the Apple-TV-style action language: fully rounded
/// capsules. The primary action is the white pill with dark label; all
/// other actions are translucent dark pills with white labels. Toggled-on
/// states tint surface and label with the accent. Height is uniform so
/// every cell in the action grid matches.
struct LiveChipButtonStyle: ButtonStyle {
  var isFilled = false
  var isActive = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.footnote.weight(isFilled ? .semibold : .medium))
      .foregroundStyle(foreground)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .frame(minHeight: 38)
      .background(
        Capsule(style: .continuous)
          .fill(background)
      )
      .overlay(
        Capsule(style: .continuous)
          .strokeBorder(
            isFilled
              ? Color.clear
              : (isActive
                ? DemoTheme.accent.opacity(0.35)
                : Color.primary.opacity(0.14)),
            lineWidth: 1
          )
      )
      .contentShape(Rectangle())
      .opacity(configuration.isPressed ? 0.6 : 1)
  }

  private var foreground: Color {
    if isFilled {
      return DemoTheme.background
    }
    return isActive ? DemoTheme.accent : .primary
  }

  private var background: Color {
    if isFilled {
      return isActive ? DemoTheme.accent : Color.primary.opacity(0.92)
    }
    return isActive ? DemoTheme.accent.opacity(0.16) : DemoTheme.elevatedSurface
  }
}
