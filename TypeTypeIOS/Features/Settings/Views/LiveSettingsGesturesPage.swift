import SwiftUI

struct LiveSettingsGesturesPage: View {
  @ObservedObject var preferences: LiveAppPreferencesStore
  @ObservedObject var viewModel: LiveSettingsViewModel
  @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

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
          help: "Hold to play faster, slide up or down to change the speed.",
          isOn: preferences.binding(\.playerLongPressSpeedEnabled),
          disabledReason: gestureReason
        )
        if viewModel.draft.holdPlaybackSpeed != nil {
          LiveOptionMenu(
            "Hold speed",
            selection: holdSpeed,
            options: LiveSettings.holdPlaybackSpeeds.map { ($0, "\($0.formatted())x") },
            help: "The speed while you hold the video.",
            disabledReason: gestureReason ?? holdReason
          )
          .disabled(viewModel.isOffline)
        }
      } header: {
        Text("On the video").liveSectionHeader()
      }
    }
    .liveGroupedList()
    .navigationTitle("Gestures")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var holdSpeed: Binding<Double> {
    Binding(get: { viewModel.draft.holdSpeed }, set: { viewModel.draft.holdPlaybackSpeed = $0 })
  }

  private var holdReason: LocalizedStringKey? {
    preferences.preferences.playerLongPressSpeedEnabled ? nil : "Turn on long-press to speed up to use this."
  }

  private var gestureReason: LocalizedStringKey? {
    preferences.preferences.usesAccessiblePlayerControls(voiceOver: voiceOverEnabled)
      ? "Off while accessible player controls are on."
      : nil
  }

  private var doubleTapReason: LocalizedStringKey? {
    preferences.preferences.playerDoubleTapSeekEnabled ? nil : "Turn on double-tap to seek to use this."
  }
}
