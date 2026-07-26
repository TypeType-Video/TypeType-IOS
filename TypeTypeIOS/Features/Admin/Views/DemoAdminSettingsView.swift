import SwiftUI

struct DemoAdminSettingsView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    Form {
      Section("Instance access") {
        Toggle("Allow registrations", isOn: adminBinding(\.allowsRegistration))
        Toggle("Allow guest mode", isOn: adminBinding(\.allowsGuests))
        Toggle("Track active sessions", isOn: adminBinding(\.tracksActiveSessions))
      }

      Section("Authentication") {
        Toggle("Allow local login", isOn: adminBinding(\.allowsLocalLogin))
        Toggle("Auto-redirect to OIDC", isOn: adminBinding(\.redirectsToOIDC))
      }

      Section("YouTube") {
        Toggle(
          "Remote YouTube login",
          isOn: adminBinding(\.allowsYouTubeRemoteLogin)
        )
      }

      Section("Access preview") {
        NavigationLink("Preview guest-disabled screen") {
          DemoGuestAccessPreviewView()
        }
      }

      Section {
        Text("Every instance switch updates the shared local admin state.")
          .foregroundStyle(.secondary)
      }
    }
  }

  private func adminBinding(
    _ keyPath: WritableKeyPath<DemoAdminSettings, Bool>
  ) -> Binding<Bool> {
    Binding(
      get: { session.adminSettings[keyPath: keyPath] },
      set: { value in
        var settings = session.adminSettings
        settings[keyPath: keyPath] = value
        session.adminSettings = settings
      }
    )
  }
}
