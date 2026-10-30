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
          options: LiveSponsorBlockMode.allCases.map { ($0.rawValue, $0.title) },
          help: modeHelp
        )
        LiveOptionMenu(
          "Minimum duration",
          selection: $viewModel.draft.sponsorBlockMinimumDuration,
          options: minimumDurations.map { ($0, $0 == 0 ? "None" : "\($0)s") },
          help: "Shorter segments are left alone.",
          disabledReason: offReason
        )
        LiveSettingToggle(
          "Mute instead of skip",
          help: "Segments play without sound instead of being jumped over.",
          isOn: $viewModel.draft.sponsorBlockMuteInsteadOfSkip,
          disabledReason: offReason
        )
        LiveSettingToggle(
          "Non-music only on music videos",
          help: "On music videos, only the parts without music are skipped.",
          isOn: $viewModel.draft.sponsorBlockSkipNonMusicOnlyOnMusicVideos,
          disabledReason: offReason
        )
      } header: {
        Text("Behavior").liveSettingsHeader()
      }
      LiveSection {
        ForEach(categories, id: \.0) { key, title in
          LiveOptionMenu(
            title,
            selection: categoryBinding(key),
            options: [("auto_skip", "Skip"), ("mark_only", "Mark"), ("disabled", "Hide")],
            disabledReason: offReason
          )
        }
      } header: {
        Text("Segments").liveSettingsHeader()
      } footer: {
        Text("Skip jumps over the segment, Mark only shows it on the progress bar, Hide ignores it.")
          .liveSettingsFooter()
      }
      LiveSection {
        LiveSettingToggle(
          "Show current segment",
          help: "Names the segment while it plays.",
          isOn: $viewModel.draft.sponsorBlockShowCurrentSegment,
          disabledReason: offReason
        )
        LiveSettingToggle(
          "Show SponsorBlock chapters",
          help: "Segments appear in the chapter list.",
          isOn: $viewModel.draft.sponsorBlockShowChapters,
          disabledReason: offReason
        )
        LiveSettingToggle(
          "Show full-video labels",
          help: "Flags videos that are entirely a sponsor or a promotion.",
          isOn: $viewModel.draft.sponsorBlockShowFullVideoLabels,
          disabledReason: offReason
        )
        LiveSettingToggle(
          "Manual skip for full-video labels",
          help: "A fully labeled video is never skipped on its own.",
          isOn: $viewModel.draft.sponsorBlockManualSkipOnFullVideo,
          disabledReason: offReason
        )
      } header: {
        Text("Display").liveSettingsHeader()
      }
    }
    .navigationTitle("SponsorBlock")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var minimumDurations: [Int] {
    let base = [0, 1, 3, 5, 10, 30]
    let current = viewModel.draft.sponsorBlockMinimumDuration
    return base.contains(current) ? base : (base + [current]).sorted()
  }

  private var isOff: Bool {
    viewModel.draft.sponsorBlockMode == LiveSponsorBlockMode.disabled.rawValue
  }

  private var offReason: LocalizedStringKey? {
    isOff ? "SponsorBlock is off." : nil
  }

  private var modeHelp: LocalizedStringKey {
    switch LiveSponsorBlockMode(rawValue: viewModel.draft.sponsorBlockMode) {
    case .autoSkip: "Segments follow the rule of their category below."
    case .markOnly: "Segments show on the progress bar and are never skipped."
    case .disabled, .none: "SponsorBlock data is ignored."
    }
  }

  private func categoryBinding(_ key: String) -> Binding<String> {
    Binding(
      get: { viewModel.draft.sponsorBlockCategoryActions[key] ?? "disabled" },
      set: { viewModel.draft.sponsorBlockCategoryActions[key] = $0 }
    )
  }
}
