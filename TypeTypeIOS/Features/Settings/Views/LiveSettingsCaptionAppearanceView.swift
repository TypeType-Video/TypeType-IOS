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
    Form {
      Section {
        Picker("Font", selection: $styles.fontFamily) {
          ForEach(fonts, id: \.1) { Text($0.0).tag($0.1) }
        }
        Picker("Size", selection: $styles.fontSize) {
          optionLabels(sizes)
        }
        Picker("Color", selection: $styles.textColor) {
          colorLabels
        }
        Picker("Opacity", selection: $styles.textOpacity) {
          optionLabels(opacities)
        }
        Picker("Edge style", selection: $styles.textShadow) {
          ForEach(shadows, id: \.1) { Text($0.0).tag($0.1) }
        }
      } header: { Text("Text").liveSectionHeader() }
      Section {
        Picker("Color", selection: $styles.textBackground) {
          colorLabels
        }
        Picker("Opacity", selection: $styles.textBackgroundOpacity) {
          optionLabels(opacities)
        }
      } header: { Text("Text background").liveSectionHeader() }
      Section {
        Picker("Color", selection: $styles.displayBackground) {
          colorLabels
        }
        Picker("Opacity", selection: $styles.displayBackgroundOpacity) {
          optionLabels(opacities)
        }
      } header: {
        Text("Caption area")
      } footer: {
        Text(
          "These preferences style native subtitles. System keeps "
            + "your iOS accessibility appearance when a value is not set."
        )
      }
    }
    .navigationTitle("Caption appearance")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.settings.caption-appearance")
  }

  @ViewBuilder
  private func optionLabels(_ values: [String]) -> some View {
    ForEach(values, id: \.self) { value in
      Text(value.isEmpty ? "System" : value).tag(value)
    }
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
