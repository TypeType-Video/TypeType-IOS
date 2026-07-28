import SwiftUI

struct LiveSettingsLanguageSection: View {
  @Binding var settings: LiveSettings

  var body: some View {
    Section("Language and captions") {
      Toggle(
        "Enable subtitles by default",
        isOn: $settings.subtitlesEnabled
      )
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
      )
      NavigationLink("Caption appearance") {
        LiveSettingsCaptionAppearanceView(
          styles: $settings.captionStyles
        )
      }
    }
  }
}
