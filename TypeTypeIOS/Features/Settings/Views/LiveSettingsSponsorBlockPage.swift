import SwiftUI

struct LiveSettingsSponsorBlockPage: View {
  @ObservedObject var viewModel: LiveSettingsViewModel

  private let categories = [
    ("sponsor", "Sponsor"),
    ("selfpromo", "Self promotion"),
    ("exclusive_access", "Exclusive access"),
    ("interaction", "Interaction reminder"),
    ("poi_highlight", "Highlight"),
    ("intro", "Intro"),
    ("outro", "Outro"),
    ("preview", "Preview"),
    ("filler", "Filler"),
    ("chapter", "Chapter"),
    ("music_offtopic", "Non-music"),
  ]

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel) {
      LiveSection {
        LiveOptionMenu(
          "Global behavior",
          selection: $viewModel.draft.sponsorBlockMode,
          options: LiveSponsorBlockMode.allCases.map { ($0.rawValue, $0.title) }
        )
        Stepper(
          "Minimum duration: \(viewModel.draft.sponsorBlockMinimumDuration)s",
          value: $viewModel.draft.sponsorBlockMinimumDuration,
          in: 0...600
        ).liveRowFill()
        Toggle("Mute instead of skip", isOn: $viewModel.draft.sponsorBlockMuteInsteadOfSkip)
          .liveRowFill()
        Toggle(
          "Non-music only on music videos",
          isOn: $viewModel.draft.sponsorBlockSkipNonMusicOnlyOnMusicVideos
        ).liveRowFill()
      } header: {
        Text("Behavior").liveSettingsHeader()
      }
      LiveSection {
        ForEach(categories, id: \.0) { key, title in
          LiveOptionMenu(
            title,
            selection: categoryBinding(key),
            options: [("auto_skip", "Skip"), ("mark_only", "Mark"), ("disabled", "Hide")]
          )
        }
      } header: {
        Text("Segments").liveSettingsHeader()
      } footer: {
        Text("Skip jumps over the segment, Mark only shows it on the progress bar, Hide ignores it.")
          .liveSettingsFooter()
      }
      LiveSection {
        Toggle("Show current segment", isOn: $viewModel.draft.sponsorBlockShowCurrentSegment)
          .liveRowFill()
        Toggle("Show SponsorBlock chapters", isOn: $viewModel.draft.sponsorBlockShowChapters)
          .liveRowFill()
        Toggle("Show full-video labels", isOn: $viewModel.draft.sponsorBlockShowFullVideoLabels)
          .liveRowFill()
        Toggle(
          "Manual skip for full-video labels",
          isOn: $viewModel.draft.sponsorBlockManualSkipOnFullVideo
        ).liveRowFill()
      } header: {
        Text("Display").liveSettingsHeader()
      }
    }
    .navigationTitle("SponsorBlock")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func categoryBinding(_ key: String) -> Binding<String> {
    Binding(
      get: { viewModel.draft.sponsorBlockCategoryActions[key] ?? "disabled" },
      set: { viewModel.draft.sponsorBlockCategoryActions[key] = $0 }
    )
  }
}
