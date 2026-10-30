import SwiftUI

struct LiveSettingsLanguagePage: View {
  @ObservedObject var viewModel: LiveSettingsViewModel

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel) {
      LiveSection {
        Toggle("Enable subtitles by default", isOn: $viewModel.draft.subtitlesEnabled)
          .liveRowFill()
        TextField("Subtitle language code", text: $viewModel.draft.defaultSubtitleLanguage)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        NavigationLink("Caption appearance") {
          LiveSettingsCaptionAppearanceView(styles: $viewModel.draft.captionStyles)
        }
      } header: {
        Text("Subtitles").liveSettingsHeader()
      } footer: {
        Text("Use a language code such as en, fr or ja.").liveSettingsFooter()
      }
      LiveSection {
        TextField("Audio language code", text: $viewModel.draft.defaultAudioLanguage)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        Toggle("Prefer original language", isOn: $viewModel.draft.preferOriginalLanguage)
          .liveRowFill()
      } header: {
        Text("Audio").liveSettingsHeader()
      } footer: {
        Text("The original language wins over dubbed tracks when both exist.").liveSettingsFooter()
      }
    }
    .navigationTitle("Language and captions")
    .navigationBarTitleDisplayMode(.inline)
  }
}
