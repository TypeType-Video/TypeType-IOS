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
      Section {
        LiveAppearancePreview()
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
      }
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
        Text("Theme").liveSettingsHeader()
      }

      LiveSection {
        LiveOptionMenu(
          "Color scheme",
          selection: preferences.binding(\.appearanceMode),
          options: LiveAppearanceMode.allCases.map { ($0, $0.title) }
        )
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
