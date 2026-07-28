import SwiftUI

extension LivePlayerOptionsSheet {
  var playbackSection: some View {
    Section("Playback") {
      Toggle(
        "Audio only",
        systemImage: "headphones",
        isOn: binding(\.audioOnly, setter: controller.setAudioOnly)
      )
      Toggle(
        "Autoplay next video",
        isOn: binding(
          \.autoplayEnabled,
          setter: controller.setAutoplay
        )
      )
      Toggle(
        "Loop video",
        isOn: binding(\.loopsPlayback, setter: controller.setLooping)
      )
      Toggle(
        "Muted",
        isOn: binding(\.muted, setter: controller.setMuted)
      )
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
      LivePlaybackSleepTimerLink(coordinator: coordinator)
    }
  }

  @ViewBuilder var qualitySection: some View {
    if !controller.availableVideoSources.isEmpty {
      Section("Quality") {
        Picker(
          "Video",
          selection: binding(
            \.selectedVideoSourceID,
            setter: controller.selectVideoSource
          )
        ) {
          Text("Automatic").tag(String?.none)
          ForEach(controller.availableVideoSources) { source in
            Text(source.displayName).tag(Optional(source.selectionID))
          }
        }
      }
    }
  }

  var tracksSection: some View {
    Section("Tracks") {
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
      )
      if controller.subtitlesEnabled,
        !controller.availableSubtitles.isEmpty {
        subtitlePicker
      }
    }
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
    Section("Community enhancements") {
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
    }
  }

  var streamInformationSection: some View {
    Section("Stream information") {
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
    }
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
