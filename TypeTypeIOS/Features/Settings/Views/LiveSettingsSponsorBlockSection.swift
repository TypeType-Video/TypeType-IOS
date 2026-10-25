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
      )
      Toggle(
        "Show current segment",
        isOn: $settings.sponsorBlockShowCurrentSegment
      )
      Toggle(
        "Show SponsorBlock chapters",
        isOn: $settings.sponsorBlockShowChapters
      )
      Toggle(
        "Show full-video labels",
        isOn: $settings.sponsorBlockShowFullVideoLabels
      )
      Toggle(
        "Manual skip for full-video labels",
        isOn: $settings.sponsorBlockManualSkipOnFullVideo
      )
      Toggle(
        "Non-music only on music videos",
        isOn: $settings.sponsorBlockSkipNonMusicOnlyOnMusicVideos
      )
      Toggle(
        "Mute instead of skip",
        isOn: $settings.sponsorBlockMuteInsteadOfSkip
      )
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
