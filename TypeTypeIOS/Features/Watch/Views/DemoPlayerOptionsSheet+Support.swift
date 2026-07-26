import SwiftUI

extension DemoPlayerOptionsSheet {
  var effectiveAudioLanguage: String {
    session.preferences.prefersOriginalLanguage
      ? "Original"
      : session.preferences.audioLanguage
  }

  var selectedRate: Float {
    switch session.preferences.playbackSpeed {
    case "0.25×": return 0.25
    case "0.5×": return 0.5
    case "0.75×": return 0.75
    case "1.25×": return 1.25
    case "1.5×": return 1.5
    case "2×": return 2
    case "3×": return 3
    case "4×": return 4
    default: return 1
    }
  }

  func binding<Value>(
    _ keyPath: WritableKeyPath<DemoSessionPreferences, Value>
  ) -> Binding<Value> {
    Binding(
      get: { session.preferences[keyPath: keyPath] },
      set: { session.setPreference(keyPath, to: $0) }
    )
  }
}
