import SwiftUI

struct LiveSettingsGesturesPage: View {
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    List {
      LiveSection {
        Toggle(
          "Accessible player controls",
          isOn: preferences.binding(\.playerAccessibleControlsEnabled)
        ).liveRowFill()
      } footer: {
        Text("Double-tap no longer seeks while this is on.").liveSettingsFooter()
      }
      LiveSection {
        Toggle(
          "Double-tap to seek",
          isOn: preferences.binding(\.playerDoubleTapSeekEnabled)
        ).liveRowFill()
        if preferences.preferences.playerDoubleTapSeekEnabled {
          LiveOptionMenu(
            "Double-tap seek time",
            selection: preferences.binding(\.playerDoubleTapSeekSeconds),
            options: [5, 10, 15, 20, 30].map { ($0, "\($0)s") }
          )
        }
        Toggle("Swipe to seek", isOn: preferences.binding(\.playerSwipeSeekEnabled)).liveRowFill()
        Toggle(
          "Brightness and volume swipe",
          isOn: preferences.binding(\.playerSwipeBrightnessVolumeEnabled)
        ).liveRowFill()
        Toggle(
          "Long-press to speed up",
          isOn: preferences.binding(\.playerLongPressSpeedEnabled)
        ).liveRowFill()
      } header: {
        Text("On the video").liveSettingsHeader()
      }
    }
    .liveGroupedList()
    .navigationTitle("Gestures")
    .navigationBarTitleDisplayMode(.inline)
  }
}
