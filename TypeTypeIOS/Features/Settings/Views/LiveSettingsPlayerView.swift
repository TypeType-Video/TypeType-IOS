import SwiftUI

struct LiveSettingsPlayerView: View {
  @ObservedObject var viewModel: LiveSettingsViewModel
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    LiveSettingsEditingPage(viewModel: viewModel) {
      LiveSettingsPlaybackSection(settings: $viewModel.draft)
      localPlaybackSection
      LiveSection {
        Toggle(
          "Accessible player controls",
          isOn: preferences.binding(\.playerAccessibleControlsEnabled)
        )
        Toggle(
          "Double-tap to seek",
          isOn: preferences.binding(\.playerDoubleTapSeekEnabled)
        )
        if preferences.preferences.playerDoubleTapSeekEnabled {
          LiveOptionMenu(
            "Double-tap seek time",
            selection: preferences.binding(\.playerDoubleTapSeekSeconds),
            options: [5, 10, 15, 20, 30].map { ($0, "\($0)s") }
          )
        }
        Toggle(
          "Swipe to seek",
          isOn: preferences.binding(\.playerSwipeSeekEnabled)
        )
        Toggle(
          "Brightness and volume swipe",
          isOn: preferences.binding(
            \.playerSwipeBrightnessVolumeEnabled
          )
        )
        Toggle(
          "Long-press to speed up",
          isOn: preferences.binding(\.playerLongPressSpeedEnabled)
        )
      } header: {
        Text("Gestures").liveSectionHeader()
      }
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
        Text("Default codec").liveSectionHeader()
      }
      LiveSection {
        Toggle(
          "Show bullet comments",
          isOn: preferences.binding(\.danmakuEnabled)
        )
        if preferences.preferences.danmakuEnabled {
          LiveOptionMenu(
            "Danmaku speed",
            selection: preferences.binding(\.danmakuSpeed),
            options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map { ($0, "\($0)x") }
          )
          LiveOptionMenu(
            "Danmaku size",
            selection: preferences.binding(\.danmakuSize),
            options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
              .map { ($0, "\(Int($0 * 100))%") }
          )
        }
      } header: {
        Text("Bullet comments").liveSectionHeader()
      }
      LiveSettingsLanguageSection(settings: $viewModel.draft)
      LiveSettingsSponsorBlockSection(settings: $viewModel.draft)
    }
    .navigationTitle("Player")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var localPlaybackSection: some View {
    LiveSection {
      Toggle(
        "Autoplay on this device",
        isOn: preferences.binding(\.playerAutoplayEnabled)
      )
      if preferences.preferences.playerAutoplayEnabled {
        LiveOptionMenu(
          "Autoplay countdown",
          selection: preferences.binding(\.playerAutoplayCountdownSeconds),
          options: [(0, "Immediate")]
            + [3, 5, 10, 15, 20, 30].map { ($0, "\($0)s") }
        )
      }
      Toggle(
        "Audio-only playback",
        isOn: preferences.binding(\.playerAudioOnlyPlayback)
      )
      Toggle(
        "Pause in background",
        isOn: preferences.binding(\.playerPauseInBackground)
      )
    } header: {
        Text("Device playback").liveSectionHeader()
      }
  }
}
