import SwiftUI
import UIKit

enum DemoTheme {
  static var accent = Color(red: 1, green: 0.30, blue: 0.32)
  static var appearanceMode = LiveAppearanceMode.system
  static var customAccentHex: String? = nil
  static var appearanceAmoled = false
  /// Bumped on every theme change; lists re-create their cells through
  /// `.id(renderToken)` so UIKit-painted cards pick the new palette up.
  static var renderToken = UUID()
  private static var lastThemeSignature = ""
  private static var lastPreferencesSignature = ""
  /// The environment colour scheme (system light/dark); used for the
  /// `.system` mode instead of UITraitCollection so system changes react.
  static var systemColorScheme: ColorScheme?
  static var appearanceTheme = LiveAppearanceTheme.typetype

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
    appearanceTheme = preferences.appearanceTheme
    customAccentHex = preferences.customAccentHex
    // Was never assigned before: `.system` mode fell back to the UIKit
    // trait collection and missed environment scheme flips.
    systemColorScheme = colorScheme
    // Rebuild token only on real theme changes: bumping it every render
    // thrashed the lists and still left stale colours behind. The resolved
    // scheme is part of the signature, so a system light/dark flip rebuilds
    // too — it changes every colour without touching any preference.
    lastPreferencesSignature = [
      preferences.accentColor.rawValue,
      preferences.appearanceMode.rawValue,
      preferences.appearanceAmoled.description,
      preferences.appearanceTheme.rawValue,
      preferences.appearanceFont.rawValue,
    ].joined(separator: "|")
    rebuildToken()
  }

  /// A system light/dark flip changes every colour without touching a
  /// preference. The preference values are cached in the statics, so the
  /// token rebuilds without reaching for a `LiveAppPreferences`.
  static func update(colorScheme: ColorScheme?) {
    systemColorScheme = colorScheme
    rebuildToken()
  }

  private static func rebuildToken() {
    let signature = lastPreferencesSignature + "|" + isDarkResolved.description
    if signature != lastThemeSignature {
      lastThemeSignature = signature
      renderToken = UUID()
    }
  }

  static func applyUIKitAppearance(
    _ preferences: LiveAppPreferences
  ) {
    // The pages paint their own backgrounds through SwiftUI's dynamic
    // theme colors. iOS 26/27 paints default fills on list rows AND on the
    // table behind them (the white boxes that swallowed the page colour),
    // and those sit in front of SwiftUI's `listRowBackground`. Neutralise
    // every UIKit layer so the rows show the page colour behind them:
    // transparent cell backgrounds, empty background views (kills the
    // Liquid Glass row fill), clear table backgrounds.
    // The list/cell appearance neutralization is retired with the Android
    // look: painting cell and table backgrounds .clear removed the grouped
    // section cards entirely (the modern iOS look needs them). Themed
    // pages handle row fills per row via `liveRowFill()`.
    // Transparent, not a surface color: painting this white put a square
    // block behind every section header, clashing with the rounded cards.
    UITableViewHeaderFooterView.appearance().backgroundColor = .clear
    // The header's backgroundView is left alone as well: the grouped look
    // wants the system chrome back.
    // iOS 26 paints the navigation bar through `_UIBarBackground`, which
    // SwiftUI's `toolbarBackground` does not reach (the white strip at the
    // top of every page). Bind the UIKit appearance to the same resolver.
    // The grouped CARD is the cell's backgroundView: paint it with the
    // theme surface and keep the cell itself clear, so rows and card read
    // as one surface (the striped interiors came from painting the cell
    // while the card container stayed system-white).
    UITableViewCell.appearance().backgroundColor = .clear
    UICollectionViewCell.appearance().backgroundColor = .clear
    let cardChrome = ThemeCardChromeView.appearance()
    cardChrome.backgroundColor = UIColor(DemoTheme.rowBackground)
    UITableViewCell.appearance().backgroundView = ThemeCardChromeView()
    UICollectionViewCell.appearance().backgroundView = ThemeCardChromeView()
    UITableView.appearance().backgroundColor = .clear
    UICollectionView.appearance().backgroundColor = .clear
    let navAppearance = UINavigationBarAppearance()
    navAppearance.configureWithOpaqueBackground()
    navAppearance.backgroundColor = dynamicColor(role: .background)
    UINavigationBar.appearance().standardAppearance = navAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    UINavigationBar.appearance().compactAppearance = navAppearance
    // The floating tab bar's band (the area behind/below the glass pill)
    // is painted by UITabBarAppearance — the legacy backgroundColor is
    // ignored there. Bind it to the page colour like the navigation bar.
    let tabAppearance = UITabBarAppearance()
    tabAppearance.configureWithOpaqueBackground()
    tabAppearance.backgroundColor = dynamicColor(role: .background)
    UITabBar.appearance().standardAppearance = tabAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabAppearance
  }

  /// Pushes the freshly built appearances onto every bar already on
  /// screen: appearance proxies only reach bars created afterwards, which
  /// is why a system light/dark flip used to leave the top area stale. No
  /// view teardown involved — navigation stacks and tabs keep their state.
  static func refreshLiveBars() {
    // The list/cell colours resolve immediately (no dynamic provider) —
    // they must be re-applied on every theme change or the settings lists
    // keep the previous theme's greys. Theme updates run on the main actor.
    MainActor.assumeIsolated {
      applyUIKitAppearance(LiveAppPreferencesStore.shared.preferences)
    }
    for scene in UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene }) {
      for window in scene.windows {
        walkBars(from: window.rootViewController)
      }
    }
  }

  private static func walkBars(from controller: UIViewController?) {
    guard let controller else { return }
    if let navigationBar = (
      controller as? UINavigationController
    )?.navigationBar {
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = dynamicColor(role: .background)
      navigationBar.standardAppearance = appearance
      navigationBar.scrollEdgeAppearance = appearance
      navigationBar.compactAppearance = appearance
    }
    if let tabBar = (
      controller as? UITabBarController
    )?.tabBar {
      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = dynamicColor(role: .background)
      tabBar.standardAppearance = appearance
      tabBar.scrollEdgeAppearance = appearance
    }
    controller.children.forEach(walkBars)
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
    // Android `Theme.kt`: AMOLED blacks the surface roles — background and
    // surface pure black (classic: `if (amoled) Color.Black`), the dynamic
    // scheme blacks the containers too (`withAmoledSurfaces`). Classic keeps
    // grey secondary roles: surfaceVariant #27272A, highest/outline #3F3F46.
    // Accent and text are never touched.
    if effectiveAmoled, isDark {
      switch role {
      case .background, .groupedBackground, .pageBackground, .surface:
        return .black
      case .groupedSurface:
        return UIColor(red: 0.153, green: 0.153, blue: 0.165, alpha: 1)  // 27272A
      case .elevatedSurface:
        return UIColor(red: 0.247, green: 0.247, blue: 0.271, alpha: 1)  // 3F3F46
      }
    }
    switch appearanceTheme {
    case .typetype:
      return lightBase(role).resolvedColor(
        with: UITraitCollection(
          userInterfaceStyle: isDark ? .dark : .light
        )
      )
    case .snow, .nord, .cream, .forest, .plum:
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

  /// AMOLED is inactive when the app is effectively light — it only applies
  /// when the app is actually dark (Dark mode, or System with a dark system).
  private static var effectiveAmoled: Bool {
    appearanceAmoled && isDarkResolved
  }

  /// The scheme for the current appearance mode: Light stays light, Dark
  /// stays dark, System follows the environment scheme.
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

  /// The system surfaces for the classic themes (Android: the classic
  /// scheme keeps system surfaces — grey page, white cards). `.systemGroupedBackground`
  /// is pure black in dark mode ("already OLED"), so the page takes the
  /// grey secondary tone and AMOLED is the only thing that goes black.
  private static func lightBase(_ role: SurfaceRole) -> UIColor {
    switch role {
    case .background, .pageBackground:
      return .secondarySystemBackground
    case .surface:
      return .tertiarySystemBackground
    case .groupedBackground:
      return .secondarySystemGroupedBackground
    case .groupedSurface:
      // Android classic surfaceVariant/surfaceContainerHigh — an elevated
      // card tone (plain white reads as "no theme" next to white cards).
      return .tertiarySystemGroupedBackground
    case .elevatedSurface:
      return .secondarySystemBackground
    }
  }

  private static func themed(_ role: SurfaceRole) -> Color {
    Color(uiColor: dynamicColor(role: role))
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
  /// Row fill: normally the page colour (flat rows), but under AMOLED the
  /// theme's surface — otherwise page and rows are both black and the
  /// theme disappears entirely.
  var rowBackground: Color
  /// Bumped on every theme change; `liveThemeRepaint()` keys subtree
  /// identity on it so statics re-render without an app refresh.
  var renderToken: UUID
}

extension DemoTheme {
  /// Static twin of `palette.rowBackground` for row content fills.
  static var rowBackground: Color {
    (effectiveAmoled && isDarkResolved) ? surface : background
  }
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
      accent: accent,
      rowBackground: DemoTheme.rowBackground,
      renderToken: renderToken
    )
  }

  private static func separatorColor() -> Color {
    return (isDarkResolved ? Color.white : Color.black).opacity(0.12)
  }

  /// Text roles follow the Android rule exactly: classic and palette
  /// themes share the scheme text (`onSurface` = Zinc950/Zinc100, NOT
  /// tinted per theme).
  private static func textPrimaryColor() -> Color {
    // Android `onSurface`: Zinc100 dark / Zinc950 light.
    return isDarkResolved
      ? Color(red: 0.957, green: 0.957, blue: 0.961)  // F4F4F5
      : Color(red: 0.035, green: 0.035, blue: 0.043)  // 09090B
  }

  private static func textSecondaryColor() -> Color {
    // Android `onSurfaceVariant`: Zinc400 dark / Zinc700 light.
    return isDarkResolved
      ? Color(red: 0.631, green: 0.631, blue: 0.667)  // A1A1AA
      : Color(red: 0.247, green: 0.247, blue: 0.275)  // 3F3F46
  }

  /// Android `themeSurfaceColors`: one surface set per theme and per
  /// light/dark mode — `(background, surface, variant, outline)`.
  static func themeSurfaceColors(
    isDark: Bool,
    theme: LiveAppearanceTheme? = nil
  ) -> (background: Color, surface: Color, variant: Color, outline: Color) {
    switch theme ?? appearanceTheme {
    case .typetype:
      // Never reached through `dynamicColor` (the system surfaces win
      // there); kept total so the function stays non-optional.
      return (Color(uiColor: .systemGroupedBackground),
              Color(uiColor: .secondarySystemGroupedBackground),
              Color(uiColor: .secondarySystemBackground),
              Color(uiColor: .secondarySystemBackground))
    case .snow:
      // Snow: a clean white design — white page and surfaces in light,
      // neutral iOS greys in dark.
      return isDark
        ? (Color(red: 0.071, green: 0.071, blue: 0.071),   // 121212
           Color(red: 0.110, green: 0.110, blue: 0.118),   // 1C1C1E
           Color(red: 0.173, green: 0.173, blue: 0.180),   // 2C2C2E
           Color(red: 0.247, green: 0.247, blue: 0.275))   // 3F3F46
        : (Color.white,                                    // FFFFFF
           Color.white,                                    // FFFFFF
           Color(red: 0.957, green: 0.957, blue: 0.961),   // F4F4F5
           Color(red: 0.831, green: 0.831, blue: 0.847))   // D4D4D8
    case .nord:
      // Android themeSurfaceColors: ECEFF4/FFFFFF/D8DEE9/8A96A8 (light),
      // 2E3440/3B4252/434C5E/616E82 (dark).
      return isDark
        ? (Color(red: 0.180, green: 0.204, blue: 0.251),
           Color(red: 0.231, green: 0.259, blue: 0.322),
           Color(red: 0.263, green: 0.298, blue: 0.369),
           Color(red: 0.380, green: 0.431, blue: 0.510))
        : (Color(red: 0.925, green: 0.937, blue: 0.957),
           Color.white,
           Color(red: 0.847, green: 0.871, blue: 0.914),
           Color(red: 0.541, green: 0.588, blue: 0.659))
    case .cream:
      // Android themeSurfaceColors: FFF7ED/FFFBEB/FED7AA/B45309 (light),
      // 261A12/3B2418/51301D/9A6A4A (dark).
      return isDark
        ? (Color(red: 0.149, green: 0.102, blue: 0.071),
           Color(red: 0.231, green: 0.141, blue: 0.094),
           Color(red: 0.318, green: 0.188, blue: 0.114),
           Color(red: 0.604, green: 0.416, blue: 0.290))
        : (Color(red: 1.0, green: 0.969, blue: 0.929),
           Color(red: 1.0, green: 0.984, blue: 0.922),
           Color(red: 0.996, green: 0.843, blue: 0.667),
           Color(red: 0.706, green: 0.325, blue: 0.035))
    case .forest:
      // Android themeSurfaceColors: F0FDF4/FFFFFF/DCFCE7/4D7C5B (light),
      // 0B1F14/102A1B/173A25/5D9270 (dark).
      return isDark
        ? (Color(red: 0.043, green: 0.122, blue: 0.078),
           Color(red: 0.063, green: 0.165, blue: 0.106),
           Color(red: 0.090, green: 0.227, blue: 0.145),
           Color(red: 0.365, green: 0.573, blue: 0.439))
        : (Color(red: 0.941, green: 0.992, blue: 0.957),
           Color.white,
           Color(red: 0.863, green: 0.988, blue: 0.906),
           Color(red: 0.302, green: 0.486, blue: 0.357))
    case .plum:
      // Android themeSurfaceColors: FAF5FF/FFFFFF/F3E8FF/8B5BA8 (light),
      // 1D1028/2A1738/3B2050/9567AD (dark).
      return isDark
        ? (Color(red: 0.114, green: 0.063, blue: 0.157),
           Color(red: 0.165, green: 0.090, blue: 0.220),
           Color(red: 0.231, green: 0.125, blue: 0.314),
           Color(red: 0.584, green: 0.404, blue: 0.678))
        : (Color(red: 0.980, green: 0.961, blue: 1.0),
           Color.white,
           Color(red: 0.953, green: 0.910, blue: 1.0),
           Color(red: 0.545, green: 0.357, blue: 0.659))
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
      .background {
        if #available(iOS 26.0, *) {
          // Liquid Glass pill, tinted with the theme colour.
          Capsule(style: .continuous)
            .fill(background.opacity(0.28))
            .glassEffect(.regular.tint(background), in: .capsule)
        } else {
          Capsule(style: .continuous)
            .fill(background)
        }
      }
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
      // `.plain`, NOT `.insetGrouped`: the grouped style draws white
      // rounded section cards behind the rows on iOS 26/27 (the "rounded
      // pills"), and row backgrounds cannot cover them — only the list
      // style removes them. Android's settings screens have no cards
      // either: flat rows and hairline dividers on the page colour.
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      // The list background IS the row colour: it shows through
      // transparent rows (NavigationLinks etc.) and in the gaps between
      // filled rows, so every page renders rows the same way. Under AMOLED
      // this is the theme surface on the black page.
      .background(palette.rowBackground)
      .environment(\.defaultMinListRowHeight, 44)
      .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
      // Rows sit FLAT on the page — never the surface role (that is for
      // feed/content cards and chips). Under AMOLED `rowBackground` switches
      // to the theme surface so the theme stays visible on the black page.
      .listRowBackground(palette.rowBackground)
      .listRowSeparatorTint(palette.separator)
      // The navigation bar takes the SAME variable as the page — otherwise
      // it stays system-white above a coloured page (the "colour is
      // different at the very top" symptom).
      .toolbarBackground(palette.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
  }
}

/// Re-creates the wrapped subtree whenever the theme palette changes. The
/// environment change re-runs the modifier body; the fresh render token
/// gives the content a new identity, so SwiftUI re-invokes the content
/// closures — which re-read the `DemoTheme.*` roles. Without it a theme
/// switch only repainted pages whose own body happened to run (the "tap
/// around first, then the new theme shows" symptom).
extension View {
  func liveThemeRepaint() -> some View {
    modifier(LiveThemeRepaintModifier())
  }
}

private struct LiveThemeRepaintModifier: ViewModifier {
  @Environment(\.demoTheme) private var palette
  @Environment(\.colorScheme) private var systemScheme

  func body(content: Content) -> some View {
    content
      .id(palette.renderToken)
      .onChange(of: systemScheme) { _, scheme in
        DemoTheme.update(colorScheme: scheme)
      }
  }
}

/// `ContentUnavailableView` and other empty states paint their own system
/// background (the black/grey boxes in themed pages). This fills the whole
/// screen with the page colour instead.
extension View {
  func liveThemedEmptyState() -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(DemoTheme.background)
  }

  /// Fills the whole list row with the row colour. iOS 26 paints system
  /// fills (white in light, black in dark) on rows whose content is a
  /// control (Button/Toggle/Stepper) — `listRowBackground` does not cover
  /// them. The fill bleeds past the row content insets to reach the row
  /// edges; outside lists it is invisible because it matches the page.
  func liveRowFill() -> some View {
    self
      .frame(maxWidth: .infinity, minHeight: 44)
      .background(
        DemoTheme.rowBackground
          .padding(.horizontal, -20)
      )
  }
}

/// Android-style selection menu: a filled surface popup with the options
/// and a checkmark on the current one (the Android theme popup look). The
/// system menu popups are Liquid Glass and cannot take the theme surface,
/// so selection rows open this popover instead.
struct LiveOptionMenu<Option: Hashable>: View {
  let title: String
  @Binding var selection: Option
  let options: [(value: Option, label: String)]
  @State private var isPresented = false
  @Environment(\.demoTheme) private var palette

  init(
    _ title: String,
    selection: Binding<Option>,
    options: [(Option, String)]
  ) {
    self.title = title
    self._selection = selection
    self.options = options.map { (value: $0.0, label: $0.1) }
  }

  var body: some View {
    Button {
      isPresented = true
    } label: {
      HStack(spacing: 12) {
        Text(title)
          .foregroundStyle(palette.textPrimary)
        Spacer(minLength: 12)
        Text(currentLabel)
          .foregroundStyle(palette.textSecondary)
          .lineLimit(1)
          // Anchored on the VALUE text so the menu drops where the selected
          // value sits (like the system pickers), not at the row centre.
          .popover(
            isPresented: $isPresented,
            attachmentAnchor: .rect(.bounds),
            arrowEdge: .top
          ) {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(options.indices, id: \.self) { index in
                Button {
                  selection = options[index].value
                  isPresented = false
                } label: {
                  HStack(spacing: 12) {
                    Text(options[index].label)
                      .foregroundStyle(palette.textPrimary)
                    Spacer(minLength: 12)
                    if options[index].value == selection {
                      Image(systemName: "checkmark")
                        .foregroundStyle(DemoTheme.accent)
                    }
                  }
                  .padding(.horizontal, 16)
                  .frame(minHeight: 44)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < options.count - 1 {
                  Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                }
              }
            }
            .frame(width: 280)
            .presentationCompactAdaptation(.popover)
            .presentationBackground(palette.surface)
            .presentationCornerRadius(20)
          }
      }
      .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
    }
    .buttonStyle(.plain)
    .liveRowFill()
  }

  private var currentLabel: String {
    options.first(where: { $0.value == selection })?.label ?? ""
  }
}

/// SwiftUI ships no `Color.systemRed`; the Settings tiles use the iOS
/// Settings palette, so bridge UIKit's adaptive system colours across.
/// They follow light/dark automatically like every other system colour.
extension Color {
  static let systemBlue = Color(uiColor: .systemBlue)
  static let systemRed = Color(uiColor: .systemRed)
  static let systemPurple = Color(uiColor: .systemPurple)
  static let systemOrange = Color(uiColor: .systemOrange)
  static let systemGreen = Color(uiColor: .systemGreen)
  static let systemTeal = Color(uiColor: .systemTeal)
  static let systemGray = Color(uiColor: .systemGray)
}

/// Compact confirmation card presented as a dropping-down popover — the
/// user wants confirms to open like the dropdowns (downward), never as a
/// sheet sliding up from the bottom.
struct LiveConfirmCard: View {
  let title: String
  var message: String? = nil
  let confirmTitle: String
  var destructive = true
  let onConfirm: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        Text(title)
          .font(.headline)
          .multilineTextAlignment(.center)
        if let message, !message.isEmpty {
          Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      Button(role: destructive ? ButtonRole.destructive : nil) {
        dismiss()
        onConfirm()
      } label: {
        Text(confirmTitle)
          .fontWeight(.semibold)
          .foregroundStyle(
            destructive ? AnyShapeStyle(Color.systemRed) : AnyShapeStyle(.tint)
          )
          .frame(maxWidth: .infinity, minHeight: 50)
      }
      .buttonStyle(.plain)

      Divider()

      Button("Cancel") { dismiss() }
        .fontWeight(.semibold)
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, minHeight: 50)
        .buttonStyle(.plain)
    }
    .frame(width: 280)
    .presentationCompactAdaptation(.popover)
  }
}

extension View {
  /// The app's standard confirm: a glass card dropping from the attached
  /// element (see LiveConfirmCard). Replaces every confirmationDialog.
  func liveConfirmPopover(
    isPresented: Binding<Bool>,
    title: String,
    message: String? = nil,
    confirmTitle: String,
    destructive: Bool = true,
    onConfirm: @escaping () -> Void
  ) -> some View {
    popover(
      isPresented: isPresented,
      attachmentAnchor: .point(.init(x: 0.5, y: 1.0)),
      arrowEdge: .top
    ) {
      LiveConfirmCard(
        title: title,
        message: message,
        confirmTitle: confirmTitle,
        destructive: destructive,
        onConfirm: onConfirm
      )
    }
  }
}

extension View {
  /// The modern iOS 26 grouped look: rounded section cards on the system
  /// grouped background. The Android-era "flat rows only" rule is retired.
  /// The scroll background must stay VISIBLE: on iOS 26 the group cards
  /// render as part of that background layer — hiding it flattened the
  /// whole list.
  func liveGroupedList() -> some View {
    self
      .listStyle(.insetGrouped)
      // The list's own background is system grey — the theme's page colour
      // must show behind the cards instead.
      .scrollContentBackground(.hidden)
      .background(DemoTheme.background)
      .environment(\.liveInGroupedList, true)
  }
}

extension View {
  /// Themed Liquid Glass card: glass tinted with the theme's surface on
  /// iOS 26, the plain theme surface below. Every glass card and pill must
  /// follow the active theme (TypeType, AMOLED, ...).
  @ViewBuilder
  func liveGlassCard(cornerRadius: CGFloat = 14) -> some View {
    if #available(iOS 26.0, *) {
      self.background {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(DemoTheme.rowBackground.opacity(0.55))
          .glassEffect(
            .regular.tint(DemoTheme.rowBackground),
            in: .rect(cornerRadius: cornerRadius)
          )
      }
    } else {
      self.background {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
          .fill(DemoTheme.rowBackground)
      }
    }
  }

  /// Themed Liquid Glass pill for compact chips (stats, actions).
  @ViewBuilder
  func liveGlassChip() -> some View {
    if #available(iOS 26.0, *) {
      self
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
          Capsule(style: .continuous)
            .fill(DemoTheme.rowBackground.opacity(0.5))
            .glassEffect(
              .regular.tint(DemoTheme.rowBackground),
              in: .capsule
            )
        }
    } else {
      self
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule(style: .continuous).fill(DemoTheme.rowBackground))
    }
  }
}

struct LiveInGroupedListKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  /// True inside a `liveGroupedList()`: grouped lists have no system header
  /// chrome to cover, so the slot bleed must not paint its band there.
  var liveInGroupedList: Bool {
    get { self[LiveInGroupedListKey.self] }
    set { self[LiveInGroupedListKey.self] = newValue }
  }
}

/// The grouped-list card behind the rows. The appearance proxy shares one
/// instance; `applyUIKitAppearance` re-tints it on theme switches.
final class ThemeCardChromeView: UIView {}
