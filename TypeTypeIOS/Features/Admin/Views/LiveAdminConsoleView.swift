import SwiftUI

struct LiveAdminConsoleView: View {
  let dependencies: AppDependencies
  let currentUserID: String

  var body: some View {
    List {
      LiveSection {
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
        if let extras = dependencies.adminExtrasService {
          NavigationLink { LiveAdminNoticeView(service: extras) } label: {
            Label("Server notice", systemImage: "megaphone")
          }
          if dependencies.recommenderEnabled {
            NavigationLink { LiveAdminRecommenderView(service: extras) } label: {
              Label("Algorithm", systemImage: "slider.horizontal.3")
            }
          }
          if dependencies.rssEnabled {
            NavigationLink { LiveAdminRssView(service: extras) } label: {
              Label("RSS feeds", systemImage: "dot.radiowaves.up.forward")
            }
          }
        }
      } header: { Text("Instance").liveSectionHeader() }

      LiveSection {
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

      LiveSection {
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
    .liveGroupedList()
    .navigationTitle("Administration")
    .navigationBarTitleDisplayMode(.inline)
    .accessibilityIdentifier("live.admin.screen")
  }
}
