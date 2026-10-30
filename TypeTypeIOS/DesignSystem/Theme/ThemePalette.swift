import SwiftUI
import UIKit

struct ThemePalette: Equatable {
  var background: Color
  var groupedBackground: Color
  var pageBackground: Color
  var surface: Color
  var groupedSurface: Color
  var elevatedSurface: Color
  var rowBackground: Color
  var separator: Color
  var textPrimary: Color
  var textSecondary: Color
  var accent: Color
  var onAccent: Color
  var chrome: ThemeChrome

  init(
    theme: LiveAppearanceTheme,
    accent: Color,
    amoled: Bool,
    isDark: Bool
  ) {
    let surfaces = ThemeSurfaces(theme: theme, amoled: amoled && isDark, isDark: isDark)
    background = Color(uiColor: surfaces.background)
    groupedBackground = Color(uiColor: surfaces.groupedBackground)
    pageBackground = Color(uiColor: surfaces.background)
    surface = Color(uiColor: surfaces.surface)
    groupedSurface = Color(uiColor: surfaces.groupedSurface)
    elevatedSurface = Color(uiColor: surfaces.elevatedSurface)
    rowBackground = Color(uiColor: surfaces.surface)
    separator = (isDark ? Color.white : Color.black).opacity(0.12)
    textPrimary = isDark ? Color(hex24: 0xF4F4F5) : Color(hex24: 0x09090B)
    textSecondary = isDark ? Color(hex24: 0xA1A1AA) : Color(hex24: 0x3F3F46)
    self.accent = accent
    onAccent = Self.readableText(on: accent, isDark: isDark)
    chrome = ThemeChrome(background: surfaces.background, row: surfaces.surface)
  }

  init(preferences: LiveAppPreferences, isDark: Bool) {
    self.init(
      theme: preferences.appearanceTheme,
      accent: preferences.accent,
      amoled: preferences.appearanceAmoled,
      isDark: isDark
    )
  }
}

extension ThemePalette {
  // Monochrome resolves to white in dark mode and yellow is light: white text would vanish on both.
  static func readableText(on accent: Color, isDark: Bool) -> Color {
    let traits = UITraitCollection(userInterfaceStyle: isDark ? .dark : .light)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard UIColor(accent).resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return .white
    }
    let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    return luminance > 0.6 ? .black : .white
  }
}

private struct ThemePaletteKey: EnvironmentKey {
  static let defaultValue = ThemePalette(
    theme: .typetype,
    accent: LiveAccentColor.red.color,
    amoled: false,
    isDark: false
  )
}

extension EnvironmentValues {
  var themePalette: ThemePalette {
    get { self[ThemePaletteKey.self] }
    set { self[ThemePaletteKey.self] = newValue }
  }
}

private extension Color {
  init(hex24: UInt32) {
    self.init(
      red: Double((hex24 >> 16) & 0xFF) / 255,
      green: Double((hex24 >> 8) & 0xFF) / 255,
      blue: Double(hex24 & 0xFF) / 255
    )
  }
}
