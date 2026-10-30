import SwiftUI

struct LiveSettingsDanmakuPage: View {
  @ObservedObject var preferences: LiveAppPreferencesStore

  var body: some View {
    List {
      LiveSection {
        Toggle("Show bullet comments", isOn: preferences.binding(\.danmakuEnabled)).liveRowFill()
        if preferences.preferences.danmakuEnabled {
          LiveOptionMenu(
            "Danmaku speed",
            selection: preferences.binding(\.danmakuSpeed),
            options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map { ($0, "\($0)x") }
          )
          LiveOptionMenu(
            "Danmaku size",
            selection: preferences.binding(\.danmakuSize),
            options: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map { ($0, "\(Int($0 * 100))%") }
          )
        }
      } footer: {
        Text("Comments that scroll across the video, on videos that have them such as NicoNico.").liveSettingsFooter()
      }
    }
    .liveGroupedList()
    .navigationTitle("Bullet comments")
    .navigationBarTitleDisplayMode(.inline)
  }
}
