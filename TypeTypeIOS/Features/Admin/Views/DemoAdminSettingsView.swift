import SwiftUI

struct DemoAdminSettingsView: View {
  @EnvironmentObject private var session: DemoSessionStore

  var body: some View {
    Form {
      Section {
        Toggle("Allow registrations", isOn: adminBinding(\.allowsRegistration)).liveRowFill()
        Toggle("Allow guest mode", isOn: adminBinding(\.allowsGuests)).liveRowFill()
        Toggle("Track active sessions", isOn: adminBinding(\.tracksActiveSessions)).liveRowFill()
      } header: { Text("Instance access").liveSectionHeader() }

      Section {
        Toggle("Allow local login", isOn: adminBinding(\.allowsLocalLogin)).liveRowFill()
        Toggle("Auto-redirect to OIDC", isOn: adminBinding(\.redirectsToOIDC)).liveRowFill()
      } header: { Text("Authentication").liveSectionHeader() }

      Section {
        Toggle(
          "Remote YouTube login",
          isOn: adminBinding(\.allowsYouTubeRemoteLogin)
        ).liveRowFill()
      } header: { Text("YouTube").liveSectionHeader() }

      Section {
        NavigationLink("Preview guest-disabled screen") {
          DemoGuestAccessPreviewView()
        }
      } header: { Text("Access preview").liveSectionHeader() }

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
