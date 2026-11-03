import SwiftUI

struct LiveSettingsLanguagePage: View {
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel) {
      LiveSection {
        LiveSettingToggle(
          "Enable subtitles by default",
          help: "Subtitles show as soon as a video starts.",
          isOn: $viewModel.draft.subtitlesEnabled
        )
        LiveOptionMenu(
          "Subtitle language",
          selection: $viewModel.draft.defaultSubtitleLanguage,
          options: LiveLanguageOptions.options,
          help: "The track picked when a video has several.",
          disabledReason: viewModel.draft.subtitlesEnabled ? nil : "Turn on subtitles to use this.",
          opensList: true
        )
        NavigationLink {
          LiveSettingsCaptionAppearanceView(styles: $viewModel.draft.captionStyles)
        } label: {
          LiveSettingText(title: "Caption appearance", detail: "Font, size and colors of subtitles.")
        }
      } header: {
        Text("Subtitles").liveSectionHeader()
      }
      LiveSection {
        LiveSettingToggle(
          "Prefer original language",
          help: "Always use the original audio track instead of a dubbed one.",
          isOn: $viewModel.draft.preferOriginalLanguage
        )
        LiveOptionMenu(
          "Audio language",
          selection: $viewModel.draft.defaultAudioLanguage,
          options: LiveLanguageOptions.options,
          help: "The track picked when a video has several.",
          disabledReason: viewModel.draft.preferOriginalLanguage
            ? "Ignored while the original language is forced."
            : nil,
          opensList: true
        )
      } header: {
        Text("Audio").liveSectionHeader()
      }
    }
    .navigationTitle("Language and captions")
    .navigationBarTitleDisplayMode(.inline)
  }
}
