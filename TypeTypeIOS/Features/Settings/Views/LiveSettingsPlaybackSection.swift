import SwiftUI

struct LiveSettingsPlaybackSection: View {
  @Binding var settings: LiveSettings

  private let qualities = [
    "auto", "144p", "240p", "360p", "480p",
    "720p", "1080p", "1440p", "2160p",
  ]

  var body: some View {
    Section {
      Toggle("Autoplay next video", isOn: $settings.autoplay).liveRowFill()
      Toggle(
        "Skip playlist autoplay screen",
        isOn: $settings.skipPlaylistAutoplayScreen
      ).liveRowFill()
      LiveOptionMenu(
        "Default quality",
        selection: $settings.defaultQuality,
        options: qualities.map { ($0, $0 == "auto" ? "Auto" : $0) }
      )
      LiveOptionMenu(
        "Default speed",
        selection: $settings.defaultPlaybackSpeed,
        options: Self.speeds.map { (Double?.some($0), "\($0)x") }
      )
      Toggle(
        "High-quality playback",
        isOn: $settings.enableHighQualityPlayback
      ).liveRowFill()
      Toggle("Start muted", isOn: $settings.muted).liveRowFill()
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
    } header: { Text("Playback").liveSettingsHeader() }
  }

  private static let speeds: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
}
