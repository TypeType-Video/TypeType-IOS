import SwiftUI

struct LiveAdminConsoleView: View {
  let dependencies: AppDependencies
  let currentUserID: String

  var body: some View {
    List {
      Section("Instance") {
        NavigationLink {
          LiveAdminSettingsView(service: dependencies.adminService)
        } label: {
          Label("Instance settings", systemImage: "server.rack")
        }
        NavigationLink {
          LiveAdminSessionsView(service: dependencies.adminService)
        } label: {
          Label("Active sessions", systemImage: "dot.radiowaves.left.and.right")
        }
      }

      Section("People and access") {
        NavigationLink {
          LiveAdminAllowListView(
            admin: dependencies.adminService,
            access: dependencies.adminAccessService,
            controls: dependencies.contentControlsService
          )
        } label: {
          Label("Allow list", systemImage: "checklist.checked")
        }
        NavigationLink {
          LiveAdminUsersView(
            service: dependencies.adminService,
            accessService: dependencies.adminAccessService,
            currentUserID: currentUserID
          )
        } label: {
          Label("Users", systemImage: "person.3")
        }
      }

      Section("Support") {
        NavigationLink {
          LiveAdminBugReportsView(
            service: dependencies.bugReportsService,
            canCreateGitHubIssue: true
          )
        } label: {
          Label("Bug reports", systemImage: "ladybug")
        }
      }
    }
    .navigationTitle("Administration")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.admin.screen")
  }
}
