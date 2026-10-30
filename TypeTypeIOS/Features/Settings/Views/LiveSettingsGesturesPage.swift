import SwiftUI

struct LiveSettingsGesturesPage: View {
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    List {
      LiveSection {
        LiveSettingToggle(
          "Accessible player controls",
          help: "Controls stay visible and the gestures below are off. On by itself with VoiceOver.",
          isOn: preferences.binding(\.playerAccessibleControlsEnabled)
        )
      }
      LiveSection {
        LiveSettingToggle(
          "Double-tap to seek",
          help: "Double-tap the left or right side to go back or forward.",
          isOn: preferences.binding(\.playerDoubleTapSeekEnabled),
          disabledReason: gestureReason
        )
        LiveOptionMenu(
          "Double-tap seek time",
          selection: preferences.binding(\.playerDoubleTapSeekSeconds),
          options: [5, 10, 15, 20, 30].map { ($0, "\($0)s") },
          disabledReason: gestureReason ?? doubleTapReason
        )
        LiveSettingToggle(
          "Swipe to seek",
          help: "Drag sideways on the video to move through it.",
          isOn: preferences.binding(\.playerSwipeSeekEnabled),
          disabledReason: gestureReason
        )
        LiveSettingToggle(
          "Brightness and volume swipe",
          help: "Drag up or down: brightness on the left, volume on the right.",
          isOn: preferences.binding(\.playerSwipeBrightnessVolumeEnabled),
          disabledReason: gestureReason
        )
        LiveSettingToggle(
          "Long-press to speed up",
          help: "Hold to play at 2x, slide up or down to change the speed.",
          isOn: preferences.binding(\.playerLongPressSpeedEnabled),
          disabledReason: gestureReason
        )
      } header: {
        Text("On the video").liveSettingsHeader()
      }
    }
    .liveGroupedList()
    .navigationTitle("Gestures")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var gestureReason: LocalizedStringKey? {
    preferences.preferences.playerAccessibleControlsEnabled
      ? "Off while accessible player controls are on."
      : nil
  }

  private var doubleTapReason: LocalizedStringKey? {
    preferences.preferences.playerDoubleTapSeekEnabled ? nil : "Turn on double-tap to seek to use this."
  }
}
