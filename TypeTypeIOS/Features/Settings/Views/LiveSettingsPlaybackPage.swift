import SwiftUI

struct LiveSettingsPlaybackPage: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  private let codecs = LiveCodecOptions.available()
  private let qualities = ["auto", "144p", "240p", "360p", "480p", "720p", "1080p", "1440p", "2160p"]
  private let speeds: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel, scope: .mixed) {
      LiveSection {
        LiveSettingToggle(
          "Autoplay next video",
          help: "The next video starts when this one ends.",
          isOn: $viewModel.draft.autoplay
        )
        .disabled(viewModel.isOffline)
        LiveOptionMenu(
          "Autoplay countdown",
          selection: preferences.binding(\.playerAutoplayCountdownSeconds),
          options: [(0, "Immediate")] + [3, 5, 10, 15, 20, 30].map { ($0, "\($0)s") },
          help: "Time before the next video starts.",
          disabledReason: autoplayReason
        )
        LiveSettingToggle(
          "Skip playlist autoplay screen",
          help: "In a playlist the next video starts at once; suggestions keep the countdown.",
          isOn: $viewModel.draft.skipPlaylistAutoplayScreen,
          disabledReason: autoplayReason
        )
        .disabled(viewModel.isOffline)
        if viewModel.draft.autoplayOnOpen != nil {
          LiveSettingToggle(
            "Autoplay on open",
            help: "A video you open starts playing at once. Off, it waits for Play.",
            isOn: flag(\.autoplayOnOpen, otherwise: true)
          )
          .disabled(viewModel.isOffline)
        }
        if viewModel.draft.hideUpcomingPlaylistVideos != nil {
          LiveSettingToggle(
            "Hide upcoming playlist videos",
            help: "The playback queue hides the videos after the current one until you show them.",
            isOn: flag(\.hideUpcomingPlaylistVideos, otherwise: false)
          )
          .disabled(viewModel.isOffline)
        }
      } header: {
        Text("Autoplay").liveSectionHeader()
      }
      LiveSection {
        Group {
          LiveOptionMenu(
            "Default quality",
            selection: $viewModel.draft.defaultQuality,
            options: qualities.map { ($0, $0 == "auto" ? "Auto" : $0) },
            help: "The resolution a video starts at."
          )
          LiveOptionMenu(
            "Default speed",
            selection: $viewModel.draft.defaultPlaybackSpeed,
            options: speeds.map { (Double?.some($0), "\($0)x") },
            help: "Applied when a video starts."
          )
        }
        .disabled(viewModel.isOffline)
        LiveOptionMenu(
          "Preferred codec",
          selection: codecBinding,
          options: codecs,
          help: "Auto prefers what this device decodes in hardware."
        )
        LiveSettingToggle(
          "Audio-only playback",
          help: "Videos start with the audio stream only, when the server has one.",
          isOn: preferences.binding(\.playerAudioOnlyPlayback)
        )
      } header: {
        Text("Video").liveSectionHeader()
      }
      LiveSection {
        LiveSettingToggle(
          "Start muted",
          help: "Videos start without sound.",
          isOn: $viewModel.draft.muted
        )
        .disabled(viewModel.isOffline)
        LiveSettingToggle(
          "Pause in background",
          help: "The video pauses when you leave the app.",
          isOn: preferences.binding(\.playerPauseInBackground)
        )
      } header: {
        Text("Sound and background").liveSectionHeader()
      }
    }
    .navigationTitle("Playback")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var autoplayReason: LocalizedStringKey? {
    viewModel.draft.autoplay ? nil : "Turn on autoplay to use this."
  }

  private func flag(_ key: WritableKeyPath<LiveSettings, Bool?>, otherwise fallback: Bool) -> Binding<Bool> {
    Binding(
      get: { viewModel.draft[keyPath: key] ?? fallback },
      set: { viewModel.draft[keyPath: key] = $0 }
    )
  }

  private var codecBinding: Binding<String> {
    Binding(
      get: { LiveCodecOptions.shown(preferences.preferences.playerPreferredCodec, among: codecs) },
      set: { preferences.binding(\.playerPreferredCodec).wrappedValue = $0 }
    )
  }
}
