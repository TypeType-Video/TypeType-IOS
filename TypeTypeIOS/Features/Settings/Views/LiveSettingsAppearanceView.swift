import SwiftUI

struct LiveSettingsAppearanceView: View {
  @Environment(\.colorScheme) private var colorScheme

  private var isEffectivelyDark: Bool {
    preferences.preferences.appearanceMode == .dark
      || (preferences.preferences.appearanceMode == .system
        && colorScheme == .dark)
  }

  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel) {
      LiveSection {
        LiveAppearanceThemeTiles(
          selection: preferences.binding(\.appearanceTheme),
          isDark: isEffectivelyDark
        )
        LiveAppearanceAccentDots(
          selection: preferences.binding(\.accentColor),
          customHex: preferences.binding(\.customAccentHex)
        )
      } header: {
        Text("Appearance").liveSectionHeader()
      }

      LiveSection {
        LiveOptionMenu(
          "Color scheme",
          selection: preferences.binding(\.appearanceMode),
          options: LiveAppearanceMode.allCases.map { ($0, $0.title) }
        )
        // The AMOLED row is visible only when the app is effectively dark
        // (Dark, or System with a dark system): in light it does nothing.
        if isEffectivelyDark {
          Toggle("AMOLED black", isOn: preferences.binding(\.appearanceAmoled))
        }
        LiveOptionMenu(
          "Font",
          selection: preferences.binding(\.appearanceFont),
          options: LiveAppearanceFont.allCases.map { ($0, $0.title) }
        )
        LiveOptionMenu(
          "Motion",
          selection: preferences.binding(\.appearanceMotion),
          options: LiveAppearanceMotion.allCases.map { ($0, $0.title) }
        )
      }
    }
    .navigationTitle("Appearance")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.settings.appearance")
  }
}
