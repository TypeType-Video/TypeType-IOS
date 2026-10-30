import SwiftUI

struct LiveSettingsPlaybackPage: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel, scope: .mixed) {
      LiveSettingsPlaybackSection(settings: $viewModel.draft)
        .disabled(viewModel.isOffline)
      LiveSettingsDevicePlaybackSection(preferences: preferences)
      LiveSection {
        LiveOptionMenu(
          "Preferred codec",
          selection: preferences.binding(\.playerPreferredCodec),
          options: [
            ("recommended", "Smart"),
            ("av1", "AV1"),
            ("vp9", "VP9"),
            ("h264", "H.264"),
          ]
        )
      } header: {
        Text("Default codec").liveSettingsHeader()
      }
    }
    .navigationTitle("Playback")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveSettingsDevicePlaybackSection: View {
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    LiveSection {
      Toggle(
        "Autoplay on this device",
        isOn: preferences.binding(\.playerAutoplayEnabled)
      ).liveRowFill()
      if preferences.preferences.playerAutoplayEnabled {
        LiveOptionMenu(
          "Autoplay countdown",
          selection: preferences.binding(\.playerAutoplayCountdownSeconds),
          options: [(0, "Immediate")] + [3, 5, 10, 15, 20, 30].map { ($0, "\($0)s") }
        )
      }
      Toggle(
        "Audio-only playback",
        isOn: preferences.binding(\.playerAudioOnlyPlayback)
      ).liveRowFill()
      Toggle(
        "Pause in background",
        isOn: preferences.binding(\.playerPauseInBackground)
      ).liveRowFill()
    } header: {
      Text("Device playback").liveSettingsHeader()
    }
  }
}
