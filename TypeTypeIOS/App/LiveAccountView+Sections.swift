import SwiftUI

extension LiveAccountView {
  var accountSection: some View {
    LiveSettingsSection("Account") {
      LiveSettingsRow(title: "Username") {
        Text(coordinator.currentUser?.publicUsername ?? "Guest")
      }
      LiveSettingsDivider()
      LiveSettingsRow(title: "Role") {
        Text(coordinator.currentUser?.role.rawValue.capitalized ?? "User")
      }
      if let user = coordinator.currentUser,
        !user.id.hasPrefix("guest:") {
        LiveSettingsDivider()
        NavigationLink {
          LiveProfileView(coordinator: coordinator, user: user)
        } label: {
          rowLabel("Profile")
        }
        if coordinator.dependencies.accountProfileService != nil {
          LiveSettingsDivider()
          NavigationLink {
            LiveAccountProfilesView(coordinator: coordinator)
          } label: {
            rowLabel("Account profiles")
          }
        }
      }
    }
  }

  var instanceSection: some View {
    LiveSettingsSection("Instance") {
      LiveSettingsRow(title: "Name") {
        Text(
          coordinator.instance?.name
            ?? coordinator.selectedServer?.name
            ?? "TypeType"
        )
      }
      if let address = coordinator.selectedServer?.baseURLString {
        LiveSettingsDivider()
        LiveSettingsRow(title: "Address") {
          Text(address)
            .multilineTextAlignment(.trailing)
            .textSelection(.enabled)
        }
      }
      if let version = coordinator.instance?.version {
        LiveSettingsDivider()
        LiveSettingsRow(title: "Version") {
          Text(version)
        }
      }
    }
  }

  var preferencesSection: some View {
    LiveSettingsSection("Preferences") {
      accountPreferences
      LiveSettingsDivider()
      NavigationLink {
        LiveSettingsView(coordinator: coordinator)
      } label: {
        rowLabel("Settings", symbol: "gearshape.fill")
      }
      LiveSettingsDivider()
      downloadsLink
      LiveSettingsDivider()
      NavigationLink {
        LiveDiagnosticsView(
          store: coordinator.dependencies.diagnosticsStore,
          scopeProvider: {
            coordinator.dependencies.diagnosticScope()
          }
        )
      } label: {
        rowLabel("Diagnostics", symbol: "ladybug.fill")
      }
      LiveSettingsDivider()
      NavigationLink {
        LiveContentControlsView(
          service: coordinator.dependencies.contentControlsService,
          canCreateGlobal: coordinator.currentUser?.role != .user
        )
      } label: {
        rowLabel("Content controls", symbol: "slash.circle.fill")
      }
      LiveSettingsDivider()
      NavigationLink {
        LiveImportView(service: coordinator.dependencies.importService)
      } label: {
        rowLabel("Import data", symbol: "square.and.arrow.up.fill")
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
          rowLabel("Notifications", symbol: "bell")
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
        LiveSettingsDivider()
        NavigationLink {
          LiveRssFeedsView(
            feedService: rssFeedService,
            subscriptionsService: coordinator.dependencies.subscriptionsService
          )
        } label: {
          rowLabel("RSS feeds", symbol: "dot.radiowaves.left.and.right")
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
        rowLabel("Downloads", symbol: "arrow.down.circle")
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
      LiveSettingsSection("Support") {
        NavigationLink {
          LiveReportIssueView(
            service: coordinator.dependencies.bugReportsService
          )
        } label: {
          rowLabel("Report a problem", symbol: "ladybug.fill")
        }
        if user.role == .admin || user.role == .moderator {
          LiveSettingsDivider()
          NavigationLink {
            LiveAdminBugReportsView(
              service: coordinator.dependencies.bugReportsService,
              canCreateGitHubIssue: user.role == .admin
            )
          } label: {
            rowLabel("Manage bug reports")
          }
        }
      }
    }
  }

  @ViewBuilder var administrationSection: some View {
    if let user = coordinator.currentUser, user.role == .admin {
      LiveSettingsSection("Administration") {
        NavigationLink {
          LiveAdminConsoleView(
            dependencies: coordinator.dependencies,
            currentUserID: user.id
          )
        } label: {
          rowLabel("Admin console")
        }
      }
    }
  }

  var signOutSection: some View {
    LiveSettingsCard {
      Button("Sign out", role: .destructive) {
        Task { await coordinator.signOut() }
      }
      .buttonStyle(.plain)
      .foregroundStyle(.red)
      .accessibilityIdentifier("live.account.sign-out")
    }
  }

  private func rowLabel(
    _ title: String,
    symbol: String? = nil
  ) -> some View {
    HStack(spacing: 16) {
      if let symbol {
        Image(systemName: symbol)
          .frame(width: 24)
          .foregroundStyle(DemoTheme.accent)
        
      }
      Text(title)
        .foregroundStyle(DemoTheme.accent)
      Spacer(minLength: 12)
    }
    .liveSettingsRow()
    .contentShape(Rectangle())
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
