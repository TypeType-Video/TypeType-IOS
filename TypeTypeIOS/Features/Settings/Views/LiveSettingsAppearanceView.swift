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
    LiveSettingsEditingPage(viewModel: viewModel, scope: .device) {
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
        Text("Theme").liveSectionHeader()
      }

      LiveSection {
        LiveOptionMenu(
          "Color scheme",
          selection: preferences.binding(\.appearanceMode),
          options: LiveAppearanceMode.allCases.map { ($0, $0.title) },
          help: "Follow the system, or always light or dark."
        )
        if isEffectivelyDark {
          LiveSettingToggle(
            "AMOLED black",
            help: "Pure black pages in dark mode.",
            isOn: preferences.binding(\.appearanceAmoled)
          )
        }
        LiveOptionMenu(
          "Font",
          selection: preferences.binding(\.appearanceFont),
          options: LiveAppearanceFont.allCases.map { ($0, $0.title) },
          help: "System uses the device typeface, Expressive a rounded one."
        )
        LiveOptionMenu(
          "Motion",
          selection: preferences.binding(\.appearanceMotion),
          options: LiveAppearanceMotion.allCases.map { ($0, $0.title) },
          help: "How much screens animate when they change."
        )
      }
    }
    .navigationTitle("Appearance")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.settings.appearance")
  }
}
