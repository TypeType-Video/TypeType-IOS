import SwiftUI

struct LiveSettingsCaptionAppearanceView: View {
  @Binding var styles: LiveCaptionStyles

  private let fonts = [
    ("System", ""),
    ("Proportional sans serif", "pro-sans"),
    ("Proportional serif", "serif"),
    ("Monospaced sans serif", "mono-sans"),
    ("Monospaced serif", "mono-serif"),
    ("Casual", "casual"),
    ("Cursive", "cursive"),
    ("Small capitals", "capitals"),
  ]
  private let sizes = ["", "50%", "75%", "100%", "150%", "200%"]
  private let opacities = ["", "0%", "25%", "50%", "75%", "100%"]
  private let shadows = [
    ("System", ""),
    ("None", "none"),
    ("Drop shadow", "drop shadow"),
    ("Raised", "raised"),
    ("Depressed", "depressed"),
    ("Outline", "outline"),
  ]
  private let colors = [
    ("System", ""),
    ("White", "#ffffff"),
    ("Yellow", "#ffff00"),
    ("Green", "#00ff00"),
    ("Cyan", "#00ffff"),
    ("Magenta", "#ff00ff"),
    ("Red", "#ff0000"),
    ("Black", "#000000"),
  ]

  var body: some View {
    List {
      LiveSection {
        LiveOptionMenu(
          "Font",
          selection: $styles.fontFamily,
          options: fonts.map { ($0.1, $0.0) }
        )
        LiveOptionMenu(
          "Size",
          selection: $styles.fontSize,
          options: sizes.map { ($0, $0.isEmpty ? "System" : $0) }
        )
        LiveOptionMenu(
          "Color",
          selection: $styles.textColor,
          options: colors.map { ($0.1, $0.0) }
        )
        LiveOptionMenu(
          "Opacity",
          selection: $styles.textOpacity,
          options: opacities.map { ($0, $0.isEmpty ? "System" : $0) }
        )
        LiveOptionMenu(
          "Edge style",
          selection: $styles.textShadow,
          options: shadows.map { ($0.1, $0.0) }
        )
      } header: { Text("Text").liveSettingsHeader() }
      LiveSection {
        LiveOptionMenu(
          "Color",
          selection: $styles.textBackground,
          options: colors.map { ($0.1, $0.0) }
        )
        LiveOptionMenu(
          "Opacity",
          selection: $styles.textBackgroundOpacity,
          options: opacities.map { ($0, $0.isEmpty ? "System" : $0) }
        )
      } header: { Text("Text background").liveSettingsHeader() }
      LiveSection {
        LiveOptionMenu(
          "Color",
          selection: $styles.displayBackground,
          options: colors.map { ($0.1, $0.0) }
        )
        LiveOptionMenu(
          "Opacity",
          selection: $styles.displayBackgroundOpacity,
          options: opacities.map { ($0, $0.isEmpty ? "System" : $0) }
        )
      } header: { Text("Caption area").liveSettingsHeader() } footer: {
        Text("Values left on System keep the caption style set in iOS accessibility settings.")
          .liveSettingsFooter()
      }
    }
      .liveGroupedList()
    .navigationTitle("Caption appearance")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.settings.caption-appearance")
  }

  @ViewBuilder
  private var colorLabels: some View {
    ForEach(colors, id: \.1) { option in
      Label {
        Text(option.0)
      } icon: {
        Circle()
          .fill(color(for: option.1))
          .overlay {
            Circle().stroke(.secondary.opacity(0.35), lineWidth: 1)
          }
      }
      .tag(option.1)
    }
  }

  private func color(for value: String) -> Color {
    switch value.lowercased() {
    case "#ffffff": return .white
    case "#ffff00": return .yellow
    case "#00ff00": return .green
    case "#00ffff": return .cyan
    case "#ff00ff": return .pink
    case "#ff0000": return .red
    case "#000000": return .black
    default: return .secondary
    }
  }
}
