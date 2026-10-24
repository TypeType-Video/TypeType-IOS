import SwiftUI

struct DemoSponsorBlockAdvancedSection: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    Section {
      Stepper(
        "Minimum segment: \(session.preferences.sponsorBlockMinimumDuration)s",
        value: binding(\.sponsorBlockMinimumDuration),
        in: 0...30
      )
      Toggle("Show current segment next to time", isOn: binding(\.sponsorBlockShowsCurrentSegment))
      Toggle("Show SponsorBlock chapters", isOn: binding(\.sponsorBlockShowsChapters))
      Toggle("Show full-video labels", isOn: binding(\.sponsorBlockShowsFullVideoLabels))
      Toggle("Manual skip for full-video labels", isOn: binding(\.sponsorBlockManualFullVideoSkip))
      Toggle("Non-music only on music videos", isOn: binding(\.sponsorBlockMusicOnly))
      Toggle("Mute segments instead of skipping", isOn: binding(\.sponsorBlockMutesInsteadOfSkips))
    } header: { Text("Advanced display").liveSectionHeader() }
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
