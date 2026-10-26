import SwiftUI

struct LiveSettingsSponsorBlockSection: View {
  @Binding var settings: LiveSettings

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
    Section {
      LiveOptionMenu(
        "Global behavior",
        selection: $settings.sponsorBlockMode,
        options: LiveSponsorBlockMode.allCases.map { ($0.rawValue, $0.title) }
      )
      ForEach(categories, id: \.0) { key, title in
        LiveOptionMenu(
          title,
          selection: categoryBinding(key),
          options: [("auto_skip", "Skip"), ("mark_only", "Mark"), ("disabled", "Hide")]
        )
      }
      Stepper(
        "Minimum duration: \(settings.sponsorBlockMinimumDuration)s",
        value: $settings.sponsorBlockMinimumDuration,
        in: 0...600
      ).liveRowFill()
      Toggle(
        "Show current segment",
        isOn: $settings.sponsorBlockShowCurrentSegment
      ).liveRowFill()
      Toggle(
        "Show SponsorBlock chapters",
        isOn: $settings.sponsorBlockShowChapters
      ).liveRowFill()
      Toggle(
        "Show full-video labels",
        isOn: $settings.sponsorBlockShowFullVideoLabels
      ).liveRowFill()
      Toggle(
        "Manual skip for full-video labels",
        isOn: $settings.sponsorBlockManualSkipOnFullVideo
      ).liveRowFill()
      Toggle(
        "Non-music only on music videos",
        isOn: $settings.sponsorBlockSkipNonMusicOnlyOnMusicVideos
      ).liveRowFill()
      Toggle(
        "Mute instead of skip",
        isOn: $settings.sponsorBlockMuteInsteadOfSkip
      ).liveRowFill()
    } header: { Text("SponsorBlock").liveSectionHeader() }
  }

  private func categoryBinding(_ key: String) -> Binding<String> {
    Binding(
      get: {
        settings.sponsorBlockCategoryActions[key] ?? "disabled"
      },
      set: {
        settings.sponsorBlockCategoryActions[key] = $0
      }
    )
  }
}
