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
    themed(.background)
  }

  static var groupedBackground: Color {
    themed(.groupedBackground)
  }

  /// The grey page colour behind grouped cards.
  static var pageBackground: Color {
    themed(.pageBackground)
  }

  static var surface: Color {
    themed(.surface)
  }

  static var groupedSurface: Color {
    themed(.groupedSurface)
  }

  static var elevatedSurface: Color {
    themed(.elevatedSurface)
  }

  enum SurfaceRole {
    case background, groupedBackground, pageBackground
    case surface, groupedSurface, elevatedSurface
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
    // The pages paint their own backgrounds through SwiftUI's dynamic
    // theme colors; painting UIKit table backgrounds here fought them and
    // cached stale colours per trait (AMOLED toggles never showed).
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
    dynamicColor(role: .background, fallbackIsDark: isDark)
  }

  /// Resolves on every draw: visible and lazy pages alike pick the theme up
  /// without a reload, and no navigation state is rebuilt.
  private static func dynamicColor(
    role: SurfaceRole,
    fallbackIsDark: Bool
  ) -> UIColor {
    UIColor { trait in
      let isDark: Bool
      switch appearanceMode {
      case .dark:
        isDark = true
      case .light:
        isDark = false
      case .system:
        isDark = trait.userInterfaceStyle == .dark
      }
      if appearanceAmoled, isDark { return .black }
      if appearancePersonality == .manga {
        return mangaColor(isDark: isDark)
      }
      switch appearanceTheme {
      case .typetype, .dynamic:
        // Light: the system base colours. Dark: the Android Zinc greys so
        // AMOLED pure black reads as a real change.
        if !isDark {
          return lightBase(role).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
          )
        }
        switch role {
        case .background, .pageBackground:
          return UIColor(red: 0.035, green: 0.035, blue: 0.043, alpha: 1)
        case .groupedBackground, .surface:
          return UIColor(red: 0.094, green: 0.094, blue: 0.106, alpha: 1)
        case .groupedSurface, .elevatedSurface:
          return UIColor(red: 0.153, green: 0.153, blue: 0.165, alpha: 1)
        }
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
  }

  private static func lightBase(_ role: SurfaceRole) -> UIColor {
    switch role {
    case .background, .surface:
      return .systemBackground
    case .groupedBackground:
      return .secondarySystemGroupedBackground
    case .pageBackground:
      return .systemGroupedBackground
    case .groupedSurface, .elevatedSurface:
      return .secondarySystemBackground
    }
  }

  private static func themed(_ role: SurfaceRole) -> Color {
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
    return Color(uiColor: dynamicColor(role: role, fallbackIsDark: isDark))
  }

  private static func resolvedUIColor(
    _ base: UIColor,
    isDark: Bool
  ) -> UIColor {
    dynamicColor(role: .background, fallbackIsDark: isDark)
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

/// Settings card in the Komi-inspired Android design: rounded 12pt
/// surface holding rows separated by inset dividers.
struct LiveSettingsCard<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    SettingsRowLayout {
      content
    }
  }
}

/// Pads every row in a settings card to the Android row metrics
/// (20 horizontal, 12 vertical, 44pt minimum height) so pages can be swept
/// Settings row in the Android design: 20/12 padding, body title,
/// muted trailing value.
struct LiveSettingsRow<Trailing: View>: View {
  let title: String
  var subtitle: String? = nil
  private let trailing: Trailing

  init(
    title: String,
    subtitle: String? = nil,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.title = title
    self.subtitle = subtitle
    self.trailing = trailing()
  }

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .foregroundStyle(.primary)
        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 12)
      trailing
        .font(.body)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .frame(minHeight: 20)
  }
}

/// Divider between rows: thin, inset 20pt like the Android settings rows.
struct LiveSettingsDivider: View {
  var body: some View {
    Rectangle()
      .fill(Color.primary.opacity(0.12))
      .frame(height: 1)
      .padding(.leading, 20)
  }
}

/// A settings section in the Android design: uppercase caption on the page
/// background, then the card with rows, then optional footer content.
struct LiveSettingsSection<Content: View, Footer: View>: View {
  let title: String
  private let content: Content
  private let footer: Footer

  init(
    _ title: String,
    @ViewBuilder content: () -> Content,
    @ViewBuilder footer: () -> Footer = { EmptyView() }
  ) {
    self.title = title
    self.content = content()
    self.footer = footer()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title)
        .liveSectionHeader()
        .padding(.horizontal, 20)
      content
      footer
    }
  }
}

/// Flows the section rows flat on the page with the Android row metrics
/// (20 horizontal, 12 vertical, 44pt minimum height) and hairline dividers.
private struct SettingsRowLayout: Layout {
  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let width = proposal.width ?? 0
    var height: CGFloat = 0
    for subview in subviews {
      let size = subview.sizeThatFits(
        ProposedViewSize(width: width - 40, height: nil)
      )
      if size.height <= 2 {
        height += 1
      } else {
        height += max(size.height + 24, 44)
      }
    }
    return CGSize(width: width, height: height)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    var y = bounds.minY
    for subview in subviews {
      let size = subview.sizeThatFits(
        ProposedViewSize(width: bounds.width - 40, height: nil)
      )
      if size.height <= 2 {
        subview.place(
          at: CGPoint(x: bounds.minX, y: y),
          anchor: .topLeading,
          proposal: ProposedViewSize(width: bounds.width, height: 1)
        )
        y += 1
        continue
      }
      let rowHeight = max(size.height + 24, 44)
      subview.place(
        at: CGPoint(x: bounds.minX + 20, y: y + (rowHeight - size.height) / 2),
        anchor: .topLeading,
        proposal: ProposedViewSize(width: bounds.width - 40, height: size.height)
      )
      y += rowHeight
    }
  }
}

extension View {
  /// Standard row padding inside settings cards (Android: 20/12, 44 min).
  func liveSettingsRow() -> some View {
    self
      .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
  }
}
