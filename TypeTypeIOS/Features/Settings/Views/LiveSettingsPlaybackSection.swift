import SwiftUI

struct LiveSettingsPlaybackSection: View {
  @Binding var settings: LiveSettings

  private let qualities = [
    "auto", "144p", "240p", "360p", "480p",
    "720p", "1080p", "1440p", "2160p",
  ]

  var body: some View {
    Section {
      Toggle("Autoplay next video", isOn: $settings.autoplay)
      Toggle(
        "Skip playlist autoplay screen",
        isOn: $settings.skipPlaylistAutoplayScreen
      )
      Picker("Default quality", selection: $settings.defaultQuality) {
        ForEach(qualities, id: \.self) { quality in
          Text(quality == "auto" ? "Auto" : quality).tag(quality)
        }
      }
      Picker("Default speed", selection: $settings.defaultPlaybackSpeed) {
        ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) {
          speed in
          Text("\(speed)x").tag(speed)
        }
      }
      Toggle(
        "High-quality playback",
        isOn: $settings.enableHighQualityPlayback
      )
      Toggle("Start muted", isOn: $settings.muted)
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Default volume")
          Spacer()
          Text("\(Int(settings.volume * 100))%")
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        Slider(value: $settings.volume, in: 0...1)
      }
    } header: { Text("Playback").liveSectionHeader() }
  }
}
