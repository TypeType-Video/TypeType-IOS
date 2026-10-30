import SwiftUI

extension LivePlayerOptionsSheet {
  var playbackSection: some View {
    LiveSection {
      Picker(selection: binding(\.playbackRate, setter: controller.setPlaybackRate)) {
        ForEach(Self.playbackRates, id: \.value) { rate in
          Text(LocalizedStringKey(rate.title)).tag(rate.value)
        }
      } label: {
        LivePlayerOptionLabel("Speed", icon: "gauge.with.dots.needle.67percent")
      }
      Toggle(isOn: binding(\.audioOnly, setter: controller.setAudioOnly)) {
        LivePlayerOptionLabel("Audio only", icon: "headphones")
      }
      Toggle(isOn: binding(\.loopsPlayback, setter: controller.setLooping)) {
        LivePlayerOptionLabel("Loop video", icon: "repeat")
      }
      Toggle(isOn: binding(\.muted, setter: controller.setMuted)) {
        LivePlayerOptionLabel("Muted", icon: "speaker.slash")
      }
      Toggle(isOn: controller.appPreferences.binding(\.playerSwipeBrightnessVolumeEnabled)) {
        LivePlayerOptionLabel(
          "Brightness and volume swipe",
          icon: "hand.draw",
          detail: "Swipe up or down on each side of the video."
        )
      }
    } header: { Text("Playback").liveSectionHeader() }
  }

  @ViewBuilder var qualitySection: some View {
    if !controller.availableVideoSources.isEmpty {
      LiveSection {
        HStack {
          LivePlayerOptionLabel("Video quality", icon: "sparkles.tv")
          Spacer(minLength: 8)
          Menu {
            Picker("Video quality", selection: Binding(
              get: { controller.selectedVideoResolution },
              set: controller.selectVideoResolution
            )) {
              Text("Automatic").tag(Int?.none)
              ForEach(LivePlaybackVideoCatalog.resolutionOptions(from: controller.availableVideoSources)) { source in
                Text(LivePlaybackVideoCatalog.detailLabel(for: source))
                  .tag(Optional(source.height))
              }
            }
            .pickerStyle(.inline)
          } label: {
            HStack(spacing: 4) {
              Text(controller.selectedVideoResolution.map { "\($0)p" } ?? String(localized: "Automatic"))
              Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
            }
            .fixedSize()
          }
          .accessibilityLabel(Text("Video quality"))
        }
      } header: { Text("Quality").liveSectionHeader() }
    }
  }

  var tracksSection: some View {
    LiveSection {
      if controller.availableAudioSources.count > 1 {
        Picker(selection: binding(\.selectedAudioSourceID, setter: controller.selectAudioSource)) {
          Text("Default").tag(String?.none)
          ForEach(controller.availableAudioSources) { source in
            Text(source.displayName).tag(Optional(source.id))
          }
        } label: {
          LivePlayerOptionLabel("Audio track", icon: "waveform")
        }
      }
      Toggle(isOn: binding(\.subtitlesEnabled, setter: controller.setSubtitlesEnabled)) {
        LivePlayerOptionLabel("Subtitles", icon: "captions.bubble")
      }
      if controller.subtitlesEnabled, !controller.availableSubtitles.isEmpty {
        Picker(selection: binding(\.selectedSubtitleLanguage, setter: controller.selectSubtitleLanguage)) {
          Text("Automatic").tag("")
          ForEach(controller.availableSubtitles) { subtitle in
            Text(subtitle.displayName).tag(subtitle.languageTag)
          }
        } label: {
          LivePlayerOptionLabel("Subtitle language", icon: "globe")
        }
      }
    } header: { Text("Audio and subtitles").liveSectionHeader() }
  }

  var communitySection: some View {
    LiveSection {
      NavigationLink {
        LivePlayerSponsorBlockOptionsView(controller: controller)
      } label: {
        LabeledContent {
          Text(LocalizedStringKey(LiveSponsorBlockMode(rawValue: controller.sponsorBlockMode)?.title ?? "Off"))
        } label: {
          LivePlayerOptionLabel("SponsorBlock", icon: "forward.end")
        }
      }
    }
  }

  var streamInformationSection: some View {
    LiveSection {
      LabeledContent {
        Text(controller.transportLabel)
      } label: {
        LivePlayerOptionLabel("Delivery", icon: "antenna.radiowaves.left.and.right")
      }
      if let video = controller.preparation?.video {
        LabeledContent {
          Text([video.displayName, video.codec].compactMap { $0 }.joined(separator: " · "))
        } label: {
          LivePlayerOptionLabel("Video", icon: "film")
        }
      }
      if let audio = controller.preparation?.audio {
        LabeledContent {
          Text([audio.displayName, audio.codec].compactMap { $0 }.joined(separator: " · "))
        } label: {
          LivePlayerOptionLabel("Audio", icon: "speaker.wave.2")
        }
      }
    } header: { Text("Stream information").liveSectionHeader() }
  }

  var reportSection: some View {
    LiveSection {
      Button {
        presentsReport = true
      } label: {
        LivePlayerOptionLabel("Report video", icon: "exclamationmark.bubble")
          .foregroundStyle(.primary)
      }
      .accessibilityIdentifier("live.player.options.report")
    }
  }

  func binding<Value>(
    _ keyPath: KeyPath<LivePlayerController, Value>,
    setter: @escaping (Value) -> Void
  ) -> Binding<Value> {
    Binding(get: { controller[keyPath: keyPath] }, set: setter)
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
