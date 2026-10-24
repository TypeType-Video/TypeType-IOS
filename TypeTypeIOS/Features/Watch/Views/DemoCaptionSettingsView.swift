import SwiftUI

struct DemoCaptionSettingsView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    Form {
      Section {
        Picker("Font", selection: binding(\.captionFont)) {
          ForEach(["System", "Rounded", "Monospaced"], id: \.self) {
            Text($0).tag($0)
          }
        }
        Picker("Size", selection: binding(\.captionSize)) {
          ForEach(["Small", "Medium", "Large", "Extra large"], id: \.self) {
            Text($0).tag($0)
          }
        }
        Picker("Text color", selection: binding(\.captionColor)) {
          ForEach(["White", "Yellow", "Cyan"], id: \.self) {
            Text($0).tag($0)
          }
        }
        LabeledContent("Background") {
          Slider(value: binding(\.captionBackgroundOpacity), in: 0...1)
            .frame(width: 150)
        }
      } header: { Text("Caption appearance").liveSectionHeader() }

      Section {
        Text("Open video, open protocol, open community")
          .font(previewFont)
          .foregroundStyle(previewColor)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.black.opacity(session.preferences.captionBackgroundOpacity))
          .frame(maxWidth: .infinity)
      } header: { Text("Preview").liveSectionHeader() }
    }
    .navigationTitle("Captions")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.player.caption-settings")
  }

  private var previewFont: Font {
    let size: CGFloat
    switch session.preferences.captionSize {
    case "Small": size = 13
    case "Large": size = 20
    case "Extra large": size = 24
    default: size = 16
    }
    switch session.preferences.captionFont {
    case "Rounded": return .system(size: size, design: .rounded)
    case "Monospaced": return .system(size: size, design: .monospaced)
    default: return .system(size: size)
    }
  }

  private var previewColor: Color {
    switch session.preferences.captionColor {
    case "Yellow": return .yellow
    case "Cyan": return .cyan
    default: return .white
    }
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
