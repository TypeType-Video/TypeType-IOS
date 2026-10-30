import UIKit

struct ThemeSurfaces {
  private(set) var background: UIColor
  let groupedBackground: UIColor
  let surface: UIColor
  let groupedSurface: UIColor
  let elevatedSurface: UIColor

  init(theme: LiveAppearanceTheme, amoled: Bool, isDark: Bool) {
    if let set = Self.palette(theme, isDark: isDark) {
      background = UIColor(hex24: set.background)
      surface = UIColor(hex24: set.surface)
      groupedSurface = UIColor(hex24: set.variant)
      elevatedSurface = UIColor(hex24: set.outline)
    } else {
      let traits = UITraitCollection(userInterfaceStyle: isDark ? .dark : .light)
      background = UIColor.secondarySystemBackground.resolvedColor(with: traits)
      surface = UIColor.tertiarySystemBackground.resolvedColor(with: traits)
      groupedSurface = UIColor.systemGray5.resolvedColor(with: traits)
      elevatedSurface = UIColor.systemGray4.resolvedColor(with: traits)
    }
    if amoled { background = .black }
    groupedBackground = background
  }

  static func palette(
    _ theme: LiveAppearanceTheme,
    isDark: Bool
  ) -> (background: UInt32, surface: UInt32, variant: UInt32, outline: UInt32)? {
    switch theme {
    case .typetype:
      return nil
    case .snow:
      return isDark ? (0x121212, 0x1C1C1E, 0x2C2C2E, 0x3F3F46) : (0xF4F4F5, 0xFFFFFF, 0xE4E4E7, 0xD4D4D8)
    case .nord:
      return isDark ? (0x2E3440, 0x3B4252, 0x434C5E, 0x616E82) : (0xECEFF4, 0xFFFFFF, 0xD8DEE9, 0x8A96A8)
    case .cream:
      return isDark ? (0x261A12, 0x3B2418, 0x51301D, 0x9A6A4A) : (0xFFF7ED, 0xFFFBEB, 0xFED7AA, 0xB45309)
    case .forest:
      return isDark ? (0x0B1F14, 0x102A1B, 0x173A25, 0x5D9270) : (0xF0FDF4, 0xFFFFFF, 0xDCFCE7, 0x4D7C5B)
    case .plum:
      return isDark ? (0x1D1028, 0x2A1738, 0x3B2050, 0x9567AD) : (0xFAF5FF, 0xFFFFFF, 0xF3E8FF, 0x8B5BA8)
    }
  }
}

extension UIColor {
  convenience init(hex24: UInt32) {
    self.init(
      red: CGFloat((hex24 >> 16) & 0xFF) / 255,
      green: CGFloat((hex24 >> 8) & 0xFF) / 255,
      blue: CGFloat(hex24 & 0xFF) / 255,
      alpha: 1
    )
  }
}
