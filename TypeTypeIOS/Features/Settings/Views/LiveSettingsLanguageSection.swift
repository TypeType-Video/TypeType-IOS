import SwiftUI

struct LiveSettingsLanguageSection: View {
  @Binding var settings: LiveSettings

  var body: some View {
    Section {
      Toggle(
        "Enable subtitles by default",
        isOn: $settings.subtitlesEnabled
      ).liveRowFill()
      TextField(
        "Subtitle language code",
        text: $settings.defaultSubtitleLanguage
      )
      .textInputAutocapitalization(.never)
      TextField(
        "Audio language code",
        text: $settings.defaultAudioLanguage
      )
      .textInputAutocapitalization(.never)
      Toggle(
        "Prefer original language",
        isOn: $settings.preferOriginalLanguage
      ).liveRowFill()
      NavigationLink("Caption appearance") {
        LiveSettingsCaptionAppearanceView(
          styles: $settings.captionStyles
        )
      }
    } header: { Text("Language and captions").liveSectionHeader() }
  }
}
