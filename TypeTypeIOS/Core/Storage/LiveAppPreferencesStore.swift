import SwiftUI

@MainActor
final class LiveAppPreferencesStore: ObservableObject {
  static let shared = LiveAppPreferencesStore()
  static let storageKey = "typetype.app-preferences.v1"

  @Published private(set) var preferences: LiveAppPreferences
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if let data = defaults.data(forKey: Self.storageKey),
      let decoded = try? JSONDecoder().decode(
        LiveAppPreferences.self,
        from: data
      ) {
      preferences = decoded
    } else if let rawValue = defaults.string(
      forKey: LiveAppearancePreference.storageKey
    ) {
      var migrated = LiveAppPreferences()
      migrated.appearanceMode = LiveAppearancePreference.mode(
        for: rawValue
      )
      preferences = migrated
    } else {
      preferences = LiveAppPreferences()
    }
  }

  func update(_ mutation: (inout LiveAppPreferences) -> Void) {
    var value = preferences
    mutation(&value)
    guard value != preferences else { return }
    preferences = value
    defaults.set(
      (try? JSONEncoder().encode(value)),
      forKey: Self.storageKey
    )
  }

  func binding<Value>(
    _ keyPath: WritableKeyPath<LiveAppPreferences, Value>
  ) -> Binding<Value> {
    Binding(
      get: { self.preferences[keyPath: keyPath] },
      set: { value in self.update { $0[keyPath: keyPath] = value } }
    )
  }
}
