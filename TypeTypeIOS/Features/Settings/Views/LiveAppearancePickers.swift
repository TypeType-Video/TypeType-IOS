import SwiftUI

/// Theme picker as live preview tiles: each theme's real surface colours in
/// a mini feed mock-up (dev feedback, plan 6.1; adapted from beta 9b680fe).
struct LiveAppearanceThemeTiles: View {
  @Environment(\.themePalette) private var palette
  @Binding var selection: LiveAppearanceTheme
  let isDark: Bool

  var body: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: 12) {
        ForEach(LiveAppearanceTheme.allCases) { theme in
          Button {
            selection = theme
          } label: {
            VStack(spacing: 6) {
              LiveAppearanceMiniScreen(theme: theme, isDark: isDark)
                .frame(width: 66, height: 96)
                .overlay {
                  RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                      palette.accent,
                      lineWidth: selection == theme ? 2.5 : 0
                    )
                }
              Text(theme.title)
                .font(
                  .caption2.weight(selection == theme ? .semibold : .regular)
                )
                .foregroundStyle(selection == theme ? palette.accent : .primary)
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(theme.title)
          .accessibilityAddTraits(selection == theme ? .isSelected : [])
          .accessibilityIdentifier("live.settings.appearance.theme.\(theme.id)")
        }
      }
      .padding(.vertical, 8)
    }
    .scrollIndicators(.hidden)
    .accessibilityIdentifier("live.settings.appearance.themes")
  }
}

/// A tiny feed mock-up drawn in one theme's real surface colours.
struct LiveAppearanceMiniScreen: View {
  let theme: LiveAppearanceTheme
  let isDark: Bool
  @Environment(\.themePalette) private var palette

  var body: some View {
    let preview = ThemePalette(theme: theme, accent: palette.accent, amoled: false, isDark: isDark)
    return RoundedRectangle(cornerRadius: 12, style: .continuous)
      .fill(preview.background)
      .overlay(alignment: .topLeading) {
        VStack(alignment: .leading, spacing: 4) {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(preview.groupedSurface)
            .frame(height: 26)
          Capsule()
            .fill(preview.textPrimary.opacity(0.75))
            .frame(width: 40, height: 5)
          Capsule()
            .fill(preview.textSecondary.opacity(0.5))
            .frame(width: 28, height: 4)
          Capsule()
            .fill(preview.accent)
            .frame(width: 22, height: 7)
        }
        .padding(7)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .strokeBorder(preview.elevatedSurface, lineWidth: 1)
      }
      .accessibilityHidden(true)
  }
}

/// Accent colours as compact circles with a checkmark on the selected one.
struct LiveAppearanceAccentDots: View {
  @Environment(\.themePalette) private var palette
  @Binding var selection: LiveAccentColor

  var body: some View {
    HStack(spacing: 0) {
      ForEach(LiveAccentColor.allCases) { accent in
        if accent == .custom {
          // The rightmost swatch opens the system colour picker and
          // applies the picked colour as the custom accent.
          ColorPicker("", selection: customColorBinding, supportsOpacity: false)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Custom accent")
            .accessibilityIdentifier("live.settings.appearance.accent.custom")
        } else {
          Button {
            selection = accent
          } label: {
            Circle()
              .fill(accent.color)
              .frame(width: 28, height: 28)
              .overlay {
                if accent == selection {
                  Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                }
              }
              .overlay {
                Circle().strokeBorder(
                  palette.separator.opacity(0.55),
                  lineWidth: 0.5
                )
              }
              .frame(maxWidth: .infinity)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel(accent.title)
          .accessibilityAddTraits(accent == selection ? .isSelected : [])
          .accessibilityIdentifier("live.settings.appearance.accent.\(accent.id)")
        }
      }
    }
    .padding(.vertical, 8)
    .accessibilityIdentifier("live.settings.appearance.accent")
  }

  /// Picking a custom colour stores it (hex) and selects the custom accent.
  private var customColorBinding: Binding<Color> {
    let hex = LiveAppPreferencesStore.shared.binding(\.customAccentHex)
    return Binding(
      get: { hex.wrappedValue.flatMap(Color.init(hex:)) ?? .accentColor },
      set: { newValue in
        hex.wrappedValue = newValue.hexString
        selection = .custom
      }
    )
  }
}
