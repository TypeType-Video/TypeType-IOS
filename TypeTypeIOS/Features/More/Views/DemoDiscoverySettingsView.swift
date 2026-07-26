import SwiftUI

struct DemoDiscoverySettingsView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    Form {
      Section("Service") {
        ForEach(["YouTube", "NicoNico", "BiliBili"], id: \.self) { service in
          Button {
            session.setPreference(\.defaultService, to: service)
          } label: {
            HStack(spacing: 12) {
              DemoServiceIcon(service: service)
              Text(service)
                .foregroundStyle(.primary)
              Spacer()
              if session.preferences.defaultService == service {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundStyle(.tint)
              } else {
                Image(systemName: "circle")
                  .foregroundStyle(.secondary)
              }
            }
          }
          .accessibilityIdentifier("demo.discovery.service.\(service.lowercased())")
        }
      }

      Section("Startup") {
        Picker("Default landing page", selection: binding(\.landingPage)) {
          Text("Home").tag("home")
          Text("Subscriptions").tag("subscriptions")
          Text("History").tag("history")
          Text("Playlists").tag("playlists")
          Text("Watch later").tag("watch-later")
          Text("Favorites").tag("favorites")
        }
      }

      Section("Discovery surfaces") {
        Toggle("Continue watching", isOn: binding(\.showsContinueWatching))
        Toggle("Home recommendations", isOn: binding(\.showsRecommendations))
        Toggle("Related videos", isOn: binding(\.showsRelated))
        Toggle("Comments and bullet comments", isOn: binding(\.loadsComments))
      }

      Section {
        DemoHideEverythingControl()
      } footer: {
        Text("The four-step confirmation and zen scene are fully local.")
      }

      Section {
        LabeledContent(
          "Active mock service",
          value: session.preferences.defaultService
        )
      }
    }
    .navigationTitle("Discovery & services")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("demo.discovery-settings.screen")
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
