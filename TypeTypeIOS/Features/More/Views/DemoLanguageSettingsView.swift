import SwiftUI

struct DemoLanguageSettingsView: View {
  @EnvironmentObject private var session: DemoSessionStore
  private let languages = [
    "Original",
    "English",
    "French",
    "Japanese",
    "German",
    "Spanish",
  ]

  var body: some View {
    Form {
      Section {
        Toggle("Subtitles", isOn: binding(\.subtitlesEnabled)).liveRowFill()
        Picker("Subtitle language", selection: binding(\.subtitleLanguage)) {
          ForEach(languages, id: \.self) { Text($0).tag($0) }
        }
        .disabled(!session.preferences.subtitlesEnabled)
        Picker("Audio language", selection: binding(\.audioLanguage)) {
          ForEach(languages, id: \.self) { Text($0).tag($0) }
        }
        .disabled(session.preferences.prefersOriginalLanguage)
        Toggle(
          "Prefer original language",
          isOn: binding(\.prefersOriginalLanguage)
        ).liveRowFill()
      } header: { Text("Language").liveSectionHeader() }
    }
    .navigationTitle("Language")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.language-settings.screen")
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
