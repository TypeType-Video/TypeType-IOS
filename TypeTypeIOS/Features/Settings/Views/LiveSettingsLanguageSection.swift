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
      DisclosureGroup("Caption appearance") {
        TextField(
          "Font family",
          text: $settings.captionStyles.fontFamily
        )
        TextField(
          "Font size",
          text: $settings.captionStyles.fontSize
        )
        TextField(
          "Text color",
          text: $settings.captionStyles.textColor
        )
        TextField(
          "Text opacity",
          text: $settings.captionStyles.textOpacity
        )
        TextField(
          "Text shadow",
          text: $settings.captionStyles.textShadow
        )
        TextField(
          "Text background",
          text: $settings.captionStyles.textBackground
        )
        TextField(
          "Text background opacity",
          text: $settings.captionStyles.textBackgroundOpacity
        )
        TextField(
          "Display background",
          text: $settings.captionStyles.displayBackground
        )
        TextField(
          "Display background opacity",
          text: $settings.captionStyles.displayBackgroundOpacity
        )
      }
    }
  }
}
