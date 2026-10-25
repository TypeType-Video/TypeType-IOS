import SwiftUI
import UIKit

enum DemoTheme {
  static var accent = Color(red: 1, green: 0.30, blue: 0.32)
  static var appearanceMode = LiveAppearanceMode.system
  static var appearanceAmoled = false
  /// Bumped on every theme change; lists re-create their cells through
  /// `.id(renderToken)` so UIKit-painted cards pick the new palette up.
  static var renderToken = UUID()
  private static var lastThemeSignature = ""
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

  /// Themed separator role — the same resolver the environment palette
  /// uses, so dividers and card borders can never disagree.
  static var separator: Color { separatorColor() }

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
    // Rebuild token only on real theme changes: bumping it every render
    // thrashed the lists and still left stale colours behind.
    let signature = [
      preferences.accentColor.rawValue,
      preferences.appearanceMode.rawValue,
      preferences.appearanceAmoled.description,
      preferences.appearanceTheme.rawValue,
      preferences.appearancePersonality.rawValue,
      preferences.appearanceFont.rawValue,
      preferences.mangaPaper.rawValue,
    ].joined(separator: "|")
    if signature != lastThemeSignature {
      lastThemeSignature = signature
      renderToken = UUID()
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
    // The section cards are UIKit-painted cells: bind them to the theme
    // surface so palette themes (Nord/Cream/Forest/Plum) colour them too.
    UITableViewCell.appearance().backgroundColor = dynamicColor(role: .surface)
    UICollectionViewCell.appearance().backgroundColor = dynamicColor(role: .surface)
    // Transparent, not a surface color: painting this white put a square
    // block behind every section header, clashing with the rounded cards.
    UITableViewHeaderFooterView.appearance().backgroundColor = .clear
    // iOS 27 paints header chrome through backgroundView (a blur material),
    // which backgroundColor alone does not replace.
    UITableViewHeaderFooterView.appearance().backgroundView = UIView()
  }

  /// Resolves immediately (no dynamic provider): UIKit caches dynamic
  /// colours per trait, which left pages on stale palettes after a theme
  /// switch. Combined with the pre-render sync and the render token, every
  /// switch repaints consistently.
  ///
  /// Every surface role resolves through the theme's surface set
  /// (Android: `themeSurfaceColors` — one set per theme and per light/dark
  /// mode, each role takes its slot). The earlier role-blind colour here
  /// collapsed cards, chips and UIKit cells into the page background on
  /// the palette themes.
  private static func dynamicColor(role: SurfaceRole) -> UIColor {
    let isDark = isDarkResolved
    if appearanceAmoled, isDark { return .black }
    if appearancePersonality == .manga {
      return mangaColor(isDark: isDark)
    }
    switch appearanceTheme {
    case .typetype, .dynamic:
      return lightBase(role).resolvedColor(
        with: UITraitCollection(
          userInterfaceStyle: isDark ? .dark : .light
        )
      )
    case .nord, .cream, .forest, .plum:
      let colors = themeSurfaceColors(isDark: isDark)
      switch role {
      case .background, .groupedBackground, .pageBackground:
        return UIColor(colors.background)
      case .surface:
        return UIColor(colors.surface)
      case .groupedSurface:
        return UIColor(colors.variant)
      case .elevatedSurface:
        return UIColor(colors.outline)
      }
    }
  }

  /// The scheme for the current appearance mode; `.system` follows the
  /// environment scheme so system light/dark changes apply immediately.
  private static var isDarkResolved: Bool {
    switch appearanceMode {
    case .dark:
      return true
    case .light:
      return false
    case .system:
      if let systemColorScheme {
        return systemColorScheme == .dark
      }
      return UITraitCollection.current.userInterfaceStyle == .dark
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
    Color(uiColor: dynamicColor(role: role))
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

/// The complete design palette — the iOS mirror of Android's `ColorScheme`:
/// ONE variable carrying every design role, injected as an environment value
/// (the CompositionLocal equivalent) so every consumer repaints live.
struct DemoThemePalette: Equatable {
  var background: Color
  var pageBackground: Color
  var surface: Color
  var groupedSurface: Color
  var elevatedSurface: Color
  var separator: Color
  var textPrimary: Color
  var textSecondary: Color
  var accent: Color
}

private struct DemoThemePaletteKey: EnvironmentKey {
  /// Computed, not cached: a `let` froze the accent at first access and
  /// left un-injected surfaces on the launch palette.
  static var defaultValue: DemoThemePalette { DemoTheme.palette() }
}

extension EnvironmentValues {
  var demoTheme: DemoThemePalette {
    get { self[DemoThemePaletteKey.self] }
    set { self[DemoThemePaletteKey.self] = newValue }
  }
}

extension DemoTheme {
  /// Builds the full palette from the current preferences (Android:
  /// `themedLightScheme`/`themedDarkScheme` derive every role at once).
  /// Every surface role comes from the same resolver the `DemoTheme.*`
  /// static roles use, so the environment palette and the statics can
  /// never disagree (the old split logic painted AMOLED and system-mode
  /// edge cases differently on each path).
  static func palette() -> DemoThemePalette {
    func color(_ role: SurfaceRole) -> Color {
      Color(uiColor: dynamicColor(role: role))
    }
    return DemoThemePalette(
      background: color(.background),
      pageBackground: color(.pageBackground),
      surface: color(.surface),
      groupedSurface: color(.groupedSurface),
      elevatedSurface: color(.elevatedSurface),
      separator: separatorColor(),
      textPrimary: textPrimaryColor(),
      textSecondary: textSecondaryColor(),
      accent: accent
    )
  }

  private static func separatorColor() -> Color {
    return (isDarkResolved ? Color.white : Color.black).opacity(0.12)
  }

  /// Theme-tinted text roles (Android: onSurface per palette).
  private static func textPrimaryColor() -> Color {
    let isDark = isDarkResolved
    if appearancePersonality == .manga {
      return isDark ? .white : .black
    }
    switch appearanceTheme {
    case .typetype, .dynamic:
      return isDark ? .white : .black
    case .nord:
      return isDark
        ? Color(red: 0.93, green: 0.94, blue: 0.96)
        : Color(red: 0.18, green: 0.20, blue: 0.25)
    case .cream:
      return isDark
        ? Color(red: 0.97, green: 0.94, blue: 0.90)
        : Color(red: 0.22, green: 0.16, blue: 0.11)
    case .forest:
      return isDark
        ? Color(red: 0.92, green: 0.98, blue: 0.95)
        : Color(red: 0.08, green: 0.20, blue: 0.13)
    case .plum:
      return isDark
        ? Color(red: 0.96, green: 0.93, blue: 1.0)
        : Color(red: 0.19, green: 0.10, blue: 0.24)
    }
  }

  private static func textSecondaryColor() -> Color {
    return textPrimaryColor().opacity(0.62)
  }

  /// Android `themeSurfaceColors`: one surface set per theme and per
  /// light/dark mode — `(background, surface, variant, outline)`.
  static func themeSurfaceColors(isDark: Bool) -> (background: Color, surface: Color, variant: Color, outline: Color) {
    switch appearanceTheme {
    case .typetype, .dynamic:
      // Never reached through `dynamicColor` (the system surfaces win
      // there); kept total so the function stays non-optional.
      return (Color(uiColor: .systemBackground),
              Color(uiColor: .systemBackground),
              Color(uiColor: .secondarySystemBackground),
              Color(uiColor: .secondarySystemBackground))
    case .nord:
      return isDark
        ? (Color(red: 0.180, green: 0.204, blue: 0.251),
           Color(red: 0.231, green: 0.259, blue: 0.322),
           Color(red: 0.263, green: 0.298, blue: 0.369),
           Color(red: 0.302, green: 0.337, blue: 0.408))
        : (Color(red: 0.925, green: 0.937, blue: 0.957),
           Color.white,
           Color(red: 0.847, green: 0.871, blue: 0.914),
           Color(red: 0.541, green: 0.588, blue: 0.659))
    case .cream:
      return isDark
        ? (Color(red: 0.15, green: 0.10, blue: 0.07),
           Color(red: 0.20, green: 0.14, blue: 0.10),
           Color(red: 0.26, green: 0.19, blue: 0.14),
           Color(red: 0.36, green: 0.27, blue: 0.20))
        : (Color(red: 1.0, green: 0.97, blue: 0.93),
           Color.white,
           Color(red: 0.96, green: 0.92, blue: 0.85),
           Color(red: 0.85, green: 0.78, blue: 0.68))
    case .forest:
      return isDark
        ? (Color(red: 0.04, green: 0.12, blue: 0.08),
           Color(red: 0.07, green: 0.18, blue: 0.12),
           Color(red: 0.10, green: 0.24, blue: 0.16),
           Color(red: 0.18, green: 0.34, blue: 0.25))
        : (Color(red: 0.94, green: 0.99, blue: 0.96),
           Color.white,
           Color(red: 0.84, green: 0.94, blue: 0.88),
           Color(red: 0.55, green: 0.73, blue: 0.62))
    case .plum:
      return isDark
        ? (Color(red: 0.11, green: 0.06, blue: 0.16),
           Color(red: 0.15, green: 0.09, blue: 0.22),
           Color(red: 0.20, green: 0.13, blue: 0.29),
           Color(red: 0.31, green: 0.20, blue: 0.42))
        : (Color(red: 0.98, green: 0.96, blue: 1.0),
           Color.white,
           Color(red: 0.92, green: 0.88, blue: 0.97),
           Color(red: 0.74, green: 0.65, blue: 0.84))
    }
  }
}

/// Environment-driven page background: repaints live on theme changes.
struct DemoThemeBackground: View {
  @Environment(\.demoTheme) private var palette

  var body: some View {
    palette.background
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

/// Settings row in the Android design: 20/12 padding, body title,
/// muted trailing value.
struct LiveSettingsRow<Trailing: View>: View {
  let title: String
  var subtitle: String? = nil
  private let trailing: Trailing
  @Environment(\.demoTheme) private var palette

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
          .foregroundStyle(palette.textPrimary)
        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(palette.textSecondary)
        }
      }
      Spacer(minLength: 12)
      trailing
        .font(.body)
        .foregroundStyle(palette.textSecondary)
        .lineLimit(1)
    }
    .frame(minHeight: 20)
  }
}

/// Divider between rows: thin, inset 20pt like the Android settings rows.
struct LiveSettingsDivider: View {
  @Environment(\.demoTheme) private var palette

  var body: some View {
    Rectangle()
      .fill(palette.separator)
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
      LiveSettingsCard { content }
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

/// Shared row-surface rule: every list row is painted with the palette's
/// surface colour, so cards follow the theme like Android's Material
/// surfaces do. Applied once per list via `.liveThemedList()`.
extension View {
  func liveThemedList() -> some View {
    modifier(LiveThemedListModifier())
  }
}

private struct LiveThemedListModifier: ViewModifier {
  @Environment(\.demoTheme) private var palette

  func body(content: Content) -> some View {
    content
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(palette.background)
      .environment(\.defaultMinListRowHeight, 44)
      .listRowBackground(palette.surface)
      .listRowSeparatorTint(palette.separator)
  }
}
