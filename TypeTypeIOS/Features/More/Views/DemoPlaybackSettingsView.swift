import SwiftUI

struct DemoPlaybackSettingsView: View {
  @EnvironmentObject var session: DemoSessionStore

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        DemoMoreSectionCard("Playback") {
          settingToggle("Autoplay", value: binding(\.autoplay)).liveRowFill()
          divider
          Stepper(
            "Autoplay countdown · \(session.preferences.autoplayCountdownSeconds)s",
            value: binding(\.autoplayCountdownSeconds),
            in: 0...60
          ).liveRowFill()
          .foregroundStyle(.primary)
          .padding(.vertical, 12)
          divider
          settingToggle(
            "Skip playlist autoplay screen",
            value: binding(\.skipPlaylistAutoplayScreen)
          ).liveRowFill()
          divider
          settingToggle("Audio-only playback", value: binding(\.audioOnlyPlayback)).liveRowFill()
          divider
          settingToggle("Background audio", value: binding(\.backgroundAudio)).liveRowFill()
          divider
          Stepper(
            "Audio boost · \(session.preferences.audioGainPercent)%",
            value: binding(\.audioGainPercent),
            in: 100...300,
            step: 25
          ).liveRowFill()
          .foregroundStyle(.primary)
          .padding(.vertical, 12)
          Text("Independent from device volume · up to 300%")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 10)
        }

        DemoMoreSectionCard("Preferred quality") {
          valuePicker(
            "Default quality",
            selection: binding(\.defaultQuality),
            values: [
              "Best available",
              "2160p",
              "1440p",
              "1080p",
              "720p",
              "480p",
              "360p",
              "240p",
              "144p",
            ]
          )
        }

        DemoMoreSectionCard("Player defaults") {
          valuePicker(
            "Playback speed",
            selection: binding(\.playbackSpeed),
            values: [
              "0.25×",
              "0.5×",
              "0.75×",
              "1×",
              "1.25×",
              "1.5×",
              "2×",
              "3×",
              "4×",
            ]
          )
          divider
          valuePicker(
            "Subtitles",
            selection: subtitleSelection,
            values: ["Off", "English", "French", "Original language"]
          )
        }
      }
      .padding(16)
    }
    .background(DemoTheme.groupedBackground)
    .navigationTitle("Playback")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.more.playback")
  }

  private func settingToggle(
    _ title: String,
    value: Binding<Bool>
  ).liveRowFill() -> some View {
    Toggle(isOn: value).liveRowFill() {
      Text(title).foregroundStyle(.primary)
    }
    .tint(Color(red: 1, green: 0.3, blue: 0.34))
    .padding(.vertical, 12)
  }

  private func valuePicker(
    _ title: String,
    selection: Binding<String>,
    values: [String]
  ) -> some View {
    Picker(title, selection: selection) {
      ForEach(values, id: \.self) { value in
        Text(value).tag(value)
      }
    }
    .pickerStyle(.menu)
    .tint(.primary)
    .padding(.vertical, 14)
  }

  private var divider: some View {
    Divider()
  }

  private func binding<Value>(
    _ keyPath: WritableKeyPath<DemoSessionPreferences, Value>
  ) -> Binding<Value> {
    Binding(
      get: { session.preferences[keyPath: keyPath] },
      set: { session.setPreference(keyPath, to: $0) }
    )
  }
}
