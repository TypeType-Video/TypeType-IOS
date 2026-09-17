import SwiftUI

extension LiveAccountView {
  var accountSection: some View {
    Section("Account") {
      LabeledContent(
        "Username",
        value: coordinator.currentUser?.publicUsername ?? "Guest"
      )
      LabeledContent(
        "Role",
        value: coordinator.currentUser?.role.rawValue.capitalized ?? "User"
      )
      if let user = coordinator.currentUser,
        !user.id.hasPrefix("guest:") {
        NavigationLink("Profile") {
          LiveProfileView(coordinator: coordinator, user: user)
        }
        if coordinator.dependencies.accountProfileService != nil {
          NavigationLink("Account profiles") {
            LiveAccountProfilesView(coordinator: coordinator)
          }
        }
      }
    }
  }
  var instanceSection: some View {
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
  }
  var preferencesSection: some View {
    Section("Preferences") {
      accountPreferences
      NavigationLink {
        LiveSettingsView(coordinator: coordinator)
      } label: {
        Label("Settings", systemImage: "gearshape.fill")
      }
      downloadsLink
      NavigationLink {
        LiveDiagnosticsView(
          store: coordinator.dependencies.diagnosticsStore,
          scopeProvider: {
            coordinator.dependencies.diagnosticScope()
          }
        )
      } label: {
        Label("Diagnostics", systemImage: "ladybug.fill")
      }
      NavigationLink {
        LiveContentControlsView(
          service: coordinator.dependencies.contentControlsService,
          canCreateGlobal: coordinator.currentUser?.role != .user
        )
      } label: {
        Label("Content controls", systemImage: "slash.circle.fill")
      }
      NavigationLink {
        LiveImportView(service: coordinator.dependencies.importService)
      } label: {
        Label("Import data", systemImage: "square.and.arrow.up.fill")
      }
    }
  }
  @ViewBuilder private var accountPreferences: some View {
    if let user = coordinator.currentUser,
      !user.id.hasPrefix("guest:") {
      NavigationLink {
        LiveNotificationsView(dependencies: coordinator.dependencies)
      } label: {
        HStack {
          Label("Notifications", systemImage: "bell")
          Spacer()
          if notificationCenter.unreadCount > 0 {
            countBadge(
              notificationCenter.unreadCount,
              label: "unread"
            )
          }
        }
      }
      if coordinator.dependencies.rssEnabled,
        let rssFeedService = coordinator.dependencies.rssFeedService {
        NavigationLink {
          LiveRssFeedsView(
            feedService: rssFeedService,
            subscriptionsService: coordinator.dependencies.subscriptionsService
          )
        } label: {
          Label("RSS feeds", systemImage: "dot.radiowaves.left.and.right")
        }
      }
    }
  }
  private var downloadsLink: some View {
    NavigationLink {
      LiveDownloadsView(
        center: downloadCenter,
        onlinePlaybackCoordinator:
          coordinator.dependencies.playbackCoordinator
      )
    } label: {
      HStack {
        Label("Downloads", systemImage: "arrow.down.circle")
        Spacer()
        if downloadCenter.activeCount > 0 {
          countBadge(
            downloadCenter.activeCount,
            label: "active downloads"
          )
        }
      }
    }
  }
  @ViewBuilder var supportSection: some View {
    if let user = coordinator.currentUser,
      !user.id.hasPrefix("guest:") {
      Section("Support") {
        NavigationLink {
          LiveReportIssueView(
            service: coordinator.dependencies.bugReportsService
          )
        } label: {
          Label("Report a problem", systemImage: "ladybug.fill")
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
  }

  @ViewBuilder var administrationSection: some View {
    if let user = coordinator.currentUser, user.role == .admin {
      Section("Administration") {
        NavigationLink("Admin console") {
          LiveAdminConsoleView(
            dependencies: coordinator.dependencies,
            currentUserID: user.id
          )
        }
      }
    }
  }

  var signOutSection: some View {
    Section {
      Button("Sign out", role: .destructive) {
        Task { await coordinator.signOut() }
      }
      .accessibilityIdentifier("live.account.sign-out")
    }
  }

  private func countBadge(
    _ count: Int,
    label: String
  ) -> some View {
    Text(String(count))
      .font(.caption.weight(.bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(DemoTheme.accent, in: Capsule())
      .accessibilityLabel("\(count) \(label)")
  }
}
