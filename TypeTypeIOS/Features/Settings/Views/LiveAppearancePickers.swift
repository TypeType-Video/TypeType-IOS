import SwiftUI

struct LiveAppearanceThemeTiles: View {
  @Binding var selection: LiveAppearanceTheme
  let isDark: Bool

  var body: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: 12) {
        ForEach(LiveAppearanceTheme.allCases) { theme in
          LiveAppearanceThemeTile(theme: theme, isDark: isDark, isSelected: selection == theme) {
            selection = theme
          }
        }
      }
      .padding(.vertical, 8)
    }
    .scrollIndicators(.hidden)
    .accessibilityIdentifier("live.settings.appearance.themes")
  }
}

struct LiveAppearanceThemeTile: View {
  let theme: LiveAppearanceTheme
  let isDark: Bool
  let isSelected: Bool
  let select: () -> Void
  @Environment(\.themePalette) private var palette

  var body: some View {
    Button(action: select) {
      VStack(spacing: 6) {
        LiveAppearanceMiniScreen(theme: theme, isDark: isDark)
          .frame(width: 66, height: 96)
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(palette.accent, lineWidth: isSelected ? 2.5 : 0)
          }
        Text(theme.title)
          .font(isSelected ? Font.caption2.weight(.semibold) : Font.caption2)
          .foregroundStyle(isSelected ? palette.accent : Color.primary)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(theme.title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityIdentifier("live.settings.appearance.theme.\(theme.id)")
  }
}

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

struct LiveAppearanceAccentDots: View {
  @Environment(\.themePalette) private var palette
  @Binding var selection: LiveAccentColor
  @Binding var customHex: String?

  var body: some View {
    HStack(spacing: 0) {
      ForEach(LiveAccentColor.allCases) { accent in
        if accent == .custom {
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

  private var customColorBinding: Binding<Color> {
    Binding(
      get: { customHex.flatMap(Color.init(hex:)) ?? .accentColor },
      set: { newValue in
        customHex = newValue.hexString
        selection = .custom
      }
    )
  }
}
