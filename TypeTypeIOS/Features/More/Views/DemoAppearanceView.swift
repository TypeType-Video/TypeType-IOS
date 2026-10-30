import SwiftUI

struct DemoAppearanceView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    Form {
      Section {
        Picker("Color scheme", selection: binding(\.appearanceMode)) {
          ForEach(["System", "Light", "Dark"], id: \.self) { option in
            Text(option).tag(option)
          }
        }
        Picker("Accent", selection: binding(\.accent)) {
          Text("Coral").tag("Coral")
          Text("Blue").tag("Blue")
          Text("Purple").tag("Purple")
        }
      } header: { Text("Appearance").liveSectionHeader() }

      Section {
        HStack(spacing: 12) {
          Image("TypeTypeLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
          VStack(alignment: .leading) {
            Text("TypeType")
              .font(.headline)
            Text(previewSummary)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 6)
      } header: { Text("Preview").liveSectionHeader() }

      Section {
        Text("These choices are stored only for this mock session.")
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Appearance")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.appearance.screen")
  }

  private var previewSummary: String {
    "\(session.preferences.appearanceMode) · \(session.preferences.accent)"
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
