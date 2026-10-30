import SwiftUI

struct DemoSponsorBlockSettingsView: View {
  @EnvironmentObject private var session: DemoSessionStore
  private let actions = ["Skip", "Mark", "Hide"]

  var body: some View {
    Form {
      Section {
        Picker("SponsorBlock behavior", selection: binding(\.sponsorBlockMode)) {
          ForEach(["Skip", "Mark", "Off"], id: \.self) { Text($0).tag($0) }
        }
        .pickerStyle(.segmented)
        .onChange(of: session.preferences.sponsorBlockMode) {
          applyGlobalMode()
        }
      } header: { Text("Global behavior").liveSectionHeader() }

      Section {
        ForEach(DemoSponsorBlockCatalog.categories) { category in
          NavigationLink {
            DemoSponsorBlockCategoryView(category: category)
          } label: {
            HStack(spacing: 12) {
              Circle()
                .fill(category.color)
                .frame(width: 11, height: 11)
              VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                Text(category.detail)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(2)
              }
              Spacer()
              Text(action(for: category.id))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      } header: { Text("SponsorBlock categories").liveSectionHeader() }

      DemoSponsorBlockAdvancedSection()
    }
    .navigationTitle("SponsorBlock")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.sponsorblock.screen")
  }

  private func action(for categoryID: String) -> String {
    session.preferences.sponsorBlockCategoryActions[categoryID] ?? "Mark"
  }

  private func applyGlobalMode() {
    let mode = session.preferences.sponsorBlockMode
    let action = mode == "Off" ? "Hide" : mode
    var values = session.preferences.sponsorBlockCategoryActions
    for category in DemoSponsorBlockCatalog.categories {
      values[category.id] = action
    }
    session.setPreference(\.sponsorBlock, to: mode != "Off")
    session.setPreference(\.sponsorBlockCategoryActions, to: values)
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
