import SwiftUI
import UIKit

/// Environment-driven page background: repaints live on theme changes.
struct DemoThemeBackground: View {
  @Environment(\.themePalette) private var palette

  var body: some View {
    palette.background
  }
}

/// Capsule action button: filled for the primary action, translucent otherwise, accent when active.
struct LiveChipButtonStyle: ButtonStyle {
  var isFilled = false
  var isActive = false
  @Environment(\.themePalette) private var palette

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
                ? palette.accent.opacity(0.35)
                : Color.primary.opacity(0.14)),
            lineWidth: 1
          )
      )
      .contentShape(Rectangle())
      .opacity(configuration.isPressed ? 0.6 : 1)
  }

  private var foreground: Color {
    if isFilled {
      return palette.background
    }
    return isActive ? palette.accent : .primary
  }

  private var background: Color {
    if isFilled {
      return isActive ? palette.accent : Color.primary.opacity(0.92)
    }
    return isActive ? palette.accent.opacity(0.16) : palette.elevatedSurface
  }
}

/// Flat feeds and queues: rows on the theme's row colour. Preference pages use `liveGroupedList()`.
extension View {
  func liveThemedList() -> some View {
    modifier(LiveThemedListModifier())
  }
}

private struct LiveThemedListModifier: ViewModifier {
  @Environment(\.themePalette) private var palette

  func body(content: Content) -> some View {
    content
      // Flat rows on the page colour; grouped lists use `liveGroupedList()`.
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      // Shows through transparent rows and the gaps between filled ones, so every row looks the same.
      .background(palette.rowBackground)
      .environment(\.defaultMinListRowHeight, 44)
      .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
      .listRowBackground(palette.rowBackground)
      .listRowSeparatorTint(palette.separator)
      // Otherwise the bar stays system white above a coloured page.
      .toolbarBackground(palette.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
  }
}

/// Empty states such as `ContentUnavailableView` paint a system background; this fills the page colour.
extension View {
  func liveThemedEmptyState() -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(DemoThemeBackground())
  }

  /// iOS 26 paints its own fill under rows whose content is a control (Toggle, Button), on top
  /// of `listRowBackground`. The row colour bleeds past the content insets to cover it.
  func liveRowFill() -> some View {
    frame(maxWidth: .infinity, minHeight: 44)
      .background(ThemeRowFill().padding(.horizontal, -20))
      .liveRowBackground()
  }
}

/// SwiftUI ships no `Color.systemRed`; the Settings tiles use the iOS
/// Settings palette, so bridge UIKit's adaptive system colours across.
/// They follow light/dark automatically like every other system colour.
extension Color {
  static let systemBlue = Color(uiColor: .systemBlue)
  static let systemRed = Color(uiColor: .systemRed)
  static let systemPurple = Color(uiColor: .systemPurple)
  static let systemIndigo = Color(uiColor: .systemIndigo)
  static let systemPink = Color(uiColor: .systemPink)
  static let systemOrange = Color(uiColor: .systemOrange)
  static let systemGreen = Color(uiColor: .systemGreen)
  static let systemTeal = Color(uiColor: .systemTeal)
  static let systemGray = Color(uiColor: .systemGray)
}

extension View {
  /// Rounded section cards on the page colour. Sections paint their own rows with
  /// `liveRowBackground()`, so the system's grouped background can go.
  func liveGroupedList() -> some View {
    modifier(LiveGroupedListModifier())
  }

}

private struct LiveGroupedListModifier: ViewModifier {
  @Environment(\.themePalette) private var palette

  func body(content: Content) -> some View {
    content
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(palette.background)
  }
}

extension View {
  /// Themed Liquid Glass card: glass tinted with the theme's row colour on iOS 26, the plain
  /// row colour below.
  func liveGlassCard(cornerRadius: CGFloat = 14) -> some View {
    background(LiveGlassFill(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), opacity: 0.55))
  }

  /// Themed Liquid Glass pill for compact chips (stats, actions).
  func liveGlassChip() -> some View {
    padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(LiveGlassFill(shape: Capsule(style: .continuous), opacity: 0.5))
  }
}

private struct LiveGlassFill<S: Shape>: View {
  let shape: S
  let opacity: Double
  @Environment(\.themePalette) private var palette

  var body: some View {
    if #available(iOS 26.0, *) {
      shape
        .fill(palette.rowBackground.opacity(opacity))
        .glassEffect(.regular.tint(palette.rowBackground), in: shape)
    } else {
      shape.fill(palette.rowBackground)
    }
  }
}
