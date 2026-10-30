import SwiftUI

struct LiveSettingsDanmakuPage: View {
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    List {
      LiveSection {
        LiveSettingToggle(
          "Show bullet comments",
          help: "Comments scroll across videos that have them, such as on NicoNico.",
          isOn: preferences.binding(\.danmakuEnabled)
        )
        LiveOptionMenu(
          "Danmaku speed",
          selection: preferences.binding(\.danmakuSpeed),
          options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map { ($0, "\($0)x") },
          disabledReason: reason
        )
        LiveOptionMenu(
          "Danmaku size",
          selection: preferences.binding(\.danmakuSize),
          options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map { ($0, "\(Int($0 * 100))%") },
          disabledReason: reason
        )
      }
    }
    .liveGroupedList()
    .navigationTitle("Bullet comments")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var reason: LocalizedStringKey? {
    preferences.preferences.danmakuEnabled ? nil : "Turn on bullet comments to use this."
  }
}
