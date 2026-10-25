import SwiftUI

struct LivePlayerSponsorBlockOptionsView: View {
  @ObservedObject var controller: LivePlayerController

  var body: some View {
    Form {
      Section {
        Picker("Global behavior", selection: modeBinding) {
          ForEach(LiveSponsorBlockMode.allCases) { mode in
            Text(mode.title).tag(mode.rawValue)
          }
        }
        Stepper(
          "Minimum duration: \(controller.sponsorBlockMinimumDuration)s",
          value: minimumDurationBinding,
          in: 0...600
        )
        Toggle(
          "Mute segments instead of skipping",
          isOn: muteInsteadOfSkipBinding
        )
        Toggle(
          "Show current segment",
          isOn: showCurrentBinding
        )
        Toggle(
          "Show SponsorBlock chapters",
          isOn: showChaptersBinding
        )
        Toggle(
          "Show full-video labels",
          isOn: showFullVideoBinding
        )
        Toggle(
          "Manual skip for full-video labels",
          isOn: manualFullVideoBinding
        )
        Toggle(
          "Non-music only on music videos",
          isOn: musicOnlyBinding
        )
      } header: { Text("Behavior").liveSectionHeader() }

      Section {
        ForEach(Self.categories, id: \.id) { category in
          Picker(
            category.title,
            selection: categoryBinding(category.id)
          ) {
            Text("Skip").tag("auto_skip")
            Text("Mark").tag("mark_only")
            Text("Hide").tag("disabled")
          }
        }
      } header: { Text("Categories").liveSectionHeader() }

      if let count = controller.stream?.sponsorBlockSegments.count {
        Section {
          LabeledContent("Segments received", value: "\(count)")
        } header: { Text("Current video").liveSectionHeader() }
      }
    }
      .id(DemoTheme.renderToken)
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(DemoTheme.background)
    .navigationTitle("SponsorBlock")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var modeBinding: Binding<String> {
    Binding(
      get: { controller.sponsorBlockMode },
      set: controller.setSponsorBlockMode
    )
  }

  private var minimumDurationBinding: Binding<Int> {
    Binding(
      get: { controller.sponsorBlockMinimumDuration },
      set: controller.setSponsorBlockMinimumDuration
    )
  }

  private var muteInsteadOfSkipBinding: Binding<Bool> {
    Binding(
      get: { controller.sponsorBlockMuteInsteadOfSkip },
      set: controller.setSponsorBlockMuteInsteadOfSkip
    )
  }

  private var showCurrentBinding: Binding<Bool> {
    Binding(
      get: { controller.sponsorBlockShowCurrentSegment },
      set: controller.setSponsorBlockShowCurrentSegment
    )
  }

  private var showChaptersBinding: Binding<Bool> {
    Binding(
      get: { controller.sponsorBlockShowChapters },
      set: controller.setSponsorBlockShowChapters
    )
  }

  private var showFullVideoBinding: Binding<Bool> {
    Binding(
      get: { controller.sponsorBlockShowFullVideoLabels },
      set: controller.setSponsorBlockShowFullVideoLabels
    )
  }

  private var manualFullVideoBinding: Binding<Bool> {
    Binding(
      get: { controller.sponsorBlockManualSkipOnFullVideo },
      set: controller.setSponsorBlockManualSkipOnFullVideo
    )
  }

  private var musicOnlyBinding: Binding<Bool> {
    Binding(
      get: {
        controller.sponsorBlockSkipNonMusicOnlyOnMusicVideos
      },
      set: controller.setSponsorBlockMusicOnly
    )
  }

  private func categoryBinding(_ category: String) -> Binding<String> {
    Binding(
      get: {
        controller.sponsorBlockCategoryActions[category] ?? "disabled"
      },
      set: {
        controller.setSponsorBlockCategoryAction(
          $0,
          category: category
        )
      }
    )
  }

  private static let categories: [(id: String, title: String)] = [
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
}
