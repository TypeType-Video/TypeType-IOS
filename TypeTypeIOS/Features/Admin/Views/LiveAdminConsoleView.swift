import SwiftUI

struct LiveAdminConsoleView: View {
  let dependencies: AppDependencies
  let currentUserID: String

  var body: some View {
    List {
      Section {
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
      } header: { Text("Instance").liveSectionHeader() }

      Section {
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
      } header: { Text("People and access").liveSectionHeader() }

      Section {
        NavigationLink {
          LiveAdminBugReportsView(
            service: dependencies.bugReportsService,
            canCreateGitHubIssue: true
          )
        } label: {
          Label("Bug reports", systemImage: "ladybug")
        }
      } header: { Text("Support").liveSectionHeader() }
    }
      .listStyle(.insetGrouped)
      .scrollContentBackground(.hidden)
      .background(DemoThemeBackground())
      .id(DemoTheme.renderToken)
      .listStyle(.insetGrouped)
    .navigationTitle("Administration")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.admin.screen")
  }
}
