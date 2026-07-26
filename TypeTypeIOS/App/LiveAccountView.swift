import SwiftUI

struct LiveAccountView: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject private var notificationCenter: LiveNotificationCenter

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    notificationCenter = coordinator.dependencies.notificationCenter
  }

  var body: some View {
    NavigationStack {
      List {
        Section("Account") {
          LabeledContent(
            "Username",
            value: coordinator.currentUser?.publicUsername
              ?? "Guest"
          )
          LabeledContent(
            "Role",
            value: coordinator.currentUser?.role.rawValue
              .capitalized ?? "User"
          )
          if let user = coordinator.currentUser,
            !user.id.hasPrefix("guest:") {
            NavigationLink("Profile") {
              LiveProfileView(
                coordinator: coordinator,
                user: user
              )
            }
          }
        }

        Section("Instance") {
          LabeledContent(
            "Name",
            value: coordinator.instance?.name
              ?? coordinator.selectedServer?.name
              ?? "TypeType"
          )
          if let address = coordinator.selectedServer?.baseURLString {
            LabeledContent("Address") {
              Text(address)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
            }
          }
          if let version = coordinator.instance?.version {
            LabeledContent("Version", value: version)
          }
        }

        Section("Preferences") {
          if let user = coordinator.currentUser,
            !user.id.hasPrefix("guest:") {
            NavigationLink {
              LiveNotificationsView(
                dependencies: coordinator.dependencies
              )
            } label: {
              HStack {
                Label("Notifications", systemImage: "bell")
                Spacer()
                if notificationCenter.unreadCount > 0 {
                  Text(String(notificationCenter.unreadCount))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(DemoTheme.accent, in: Capsule())
                    .accessibilityLabel(
                      "\(notificationCenter.unreadCount) unread"
                    )
                }
              }
            }
            NavigationLink("YouTube session") {
              LiveYouTubeSessionView(
                baseURL: coordinator.selectedServer?.baseURL,
                remoteLoginEnabled:
                  coordinator.instance?.youtubeRemoteLoginEnabled == true,
                service: coordinator.dependencies.youtubeSessionService
              )
            }
          }
          NavigationLink("Settings") {
            LiveSettingsView(
              dependencies: coordinator.dependencies
            )
          }
          NavigationLink("Content controls") {
            LiveContentControlsView(
              service: coordinator.dependencies.contentControlsService,
              canCreateGlobal: coordinator.currentUser?.role != .user
            )
          }
          NavigationLink("Import data") {
            LiveImportView(
              service: coordinator.dependencies.importService
            )
          }
        }

        if let user = coordinator.currentUser,
          !user.id.hasPrefix("guest:") {
          Section("Support") {
            NavigationLink("Report a problem") {
              LiveReportIssueView(
                service: coordinator.dependencies.bugReportsService
              )
            }
            if user.role == .admin || user.role == .moderator {
              NavigationLink("Manage bug reports") {
                LiveAdminBugReportsView(
                  service: coordinator.dependencies.bugReportsService,
                  canCreateGitHubIssue: user.role == .admin
                )
              }
            }
          }
        }

        if let user = coordinator.currentUser,
          user.role == .admin {
          Section("Administration") {
            NavigationLink("Admin console") {
              LiveAdminConsoleView(
                dependencies: coordinator.dependencies,
                currentUserID: user.id
              )
            }
          }
        }

        Section {
          Button("Sign out", role: .destructive) {
            Task { await coordinator.signOut() }
          }
          .accessibilityIdentifier("live.account.sign-out")
        }
      }
      .navigationTitle("More")
    }
    .accessibilityIdentifier("live.account.screen")
  }
}
