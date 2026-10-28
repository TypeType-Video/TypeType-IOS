import SwiftUI

extension LivePlayerOptionsSheet {
  var playbackSection: some View {
    Section {
      Toggle(
        "Audio only",
        systemImage: "headphones",
        isOn: binding(\.audioOnly, setter: controller.setAudioOnly)
      ).liveRowFill()
      Toggle(
        "Loop video",
        isOn: binding(\.loopsPlayback, setter: controller.setLooping)
      ).liveRowFill()
      Toggle(
        "Muted",
        isOn: binding(\.muted, setter: controller.setMuted)
      ).liveRowFill()
      Toggle(
        "Brightness and volume swipe",
        isOn: LiveAppPreferencesStore.shared.binding(
          \.playerSwipeBrightnessVolumeEnabled
        )
      ).liveRowFill()
      Picker(
        "Speed",
        selection: binding(
          \.playbackRate,
          setter: controller.setPlaybackRate
        )
      ) {
        ForEach(Self.playbackRates, id: \.value) { rate in
          Text(rate.title).tag(rate.value)
        }
      }
    } header: { Text("Playback").liveSectionHeader() }
  }

  @ViewBuilder var qualitySection: some View {
    if !controller.availableVideoSources.isEmpty {
      Section {
        Picker(
          "Video",
          selection: Binding(
            get: { controller.selectedVideoResolution },
            set: controller.selectVideoResolution
          )
        ) {
          Text("Automatic").tag(Int?.none)
          ForEach(
            LivePlaybackVideoCatalog.resolutionOptions(
              from: controller.availableVideoSources
            )
          ) { source in
            Text(LivePlaybackVideoCatalog.detailLabel(for: source))
              .tag(Optional(source.height))
          }
        }
      } header: { Text("Quality").liveSectionHeader() }
    }
  }

  var tracksSection: some View {
    Section {
      if controller.availableAudioSources.count > 1 {
        Picker(
          "Audio",
          selection: binding(
            \.selectedAudioSourceID,
            setter: controller.selectAudioSource
          )
        ) {
          Text("Default").tag(String?.none)
          ForEach(controller.availableAudioSources) { source in
            Text(source.displayName).tag(Optional(source.id))
          }
        }
      }
      Toggle(
        "Subtitles",
        isOn: binding(
          \.subtitlesEnabled,
          setter: controller.setSubtitlesEnabled
        )
      ).liveRowFill()
      if controller.subtitlesEnabled,
        !controller.availableSubtitles.isEmpty {
        subtitlePicker
      }
    } header: { Text("Tracks").liveSectionHeader() }
  }

  private var subtitlePicker: some View {
    Picker(
      "Language",
      selection: binding(
        \.selectedSubtitleLanguage,
        setter: controller.selectSubtitleLanguage
      )
    ) {
      Text("Automatic").tag("")
      ForEach(controller.availableSubtitles) { subtitle in
        Text(subtitle.displayName).tag(subtitle.languageTag)
      }
    }
  }

  var communitySection: some View {
    Section {
      NavigationLink {
        LivePlayerSponsorBlockOptionsView(controller: controller)
      } label: {
        LabeledContent(
          "SponsorBlock",
          value: LiveSponsorBlockMode(
            rawValue: controller.sponsorBlockMode
          )?.title ?? "Off"
        )
      }
    } header: { Text("Community enhancements").liveSectionHeader() }
  }

  var streamInformationSection: some View {
    Section {
      LabeledContent("Delivery", value: controller.transportLabel)
      if let video = controller.preparation?.video {
        LabeledContent(
          "Video",
          value: [video.displayName, video.codec]
            .compactMap { $0 }
            .joined(separator: " · ")
        )
      }
      if let audio = controller.preparation?.audio {
        LabeledContent(
          "Audio",
          value: [audio.displayName, audio.codec]
            .compactMap { $0 }
            .joined(separator: " · ")
        )
      }
    } header: { Text("Stream information").liveSectionHeader() }
  }

  func binding<Value>(
    _ keyPath: KeyPath<LivePlayerController, Value>,
    setter: @escaping (Value) -> Void
  ) -> Binding<Value> {
    Binding(
      get: { controller[keyPath: keyPath] },
      set: setter
    )
  }

  private static let playbackRates: [(title: String, value: Float)] = [
    ("0.25×", 0.25),
    ("0.5×", 0.5),
    ("0.75×", 0.75),
    ("Normal", 1),
    ("1.25×", 1.25),
    ("1.5×", 1.5),
    ("2×", 2),
    ("3×", 3),
    ("4×", 4),
  ]
}

extension LivePlayerOptionsSheet {
  var reportSection: some View {
    Section {
      Button {
        presentsReport = true
      } label: {
        Label("Report video", systemImage: "exclamationmark.bubble")
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("live.player.options.report")
    } header: {
      Text("Support").liveSectionHeader()
    }
  }
}
