import SwiftUI

extension LiveAccountView {
  var accountSection: some View {
    Section {
      if let user = coordinator.currentUser, !user.id.hasPrefix("guest:") {
        NavigationLink {
          LiveProfileView(coordinator: coordinator, user: user)
        } label: {
          HStack(spacing: 14) {
            accountAvatar(for: user)
            VStack(alignment: .leading, spacing: 2) {
              Text(user.publicUsername ?? "TypeType user")
                .font(.headline)
                .foregroundStyle(.primary)
              Text(user.role.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
          .padding(.vertical, 2)
        }
        .accessibilityIdentifier("live.account.profile")
        if coordinator.dependencies.accountProfileService != nil {
          NavigationLink {
            LiveAccountProfilesView(coordinator: coordinator)
          } label: {
            Text("Account profiles")
          }
        }
      } else {
        LabeledContent("Username", value: "Guest")
        LabeledContent("Role", value: "Guest")
      }
    } header: {
      Text("Account")
    }
  }
  var instanceSection: some View {
    Section {
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
    } header: {
      Text("Instance")
    }
  }
  var preferencesSection: some View {
    Section {
      LiveSettingsEntry(coordinator: coordinator) {
        LiveSettingsRowLabel(title: "Settings", icon: "gearshape.fill")
      }
      downloadsLink
      NavigationLink {
        LiveNotificationsView(dependencies: coordinator.dependencies)
      } label: {
        HStack(spacing: 14) {
          LiveSettingsIconTile(icon: "bell.fill")
          Text("Notifications")
          Spacer(minLength: 0)
          if notificationCenter.unreadCount > 0 {
            LiveCountBadge(count: notificationCenter.unreadCount)
              .accessibilityLabel(Text("^[\(notificationCenter.unreadCount) unread notification](inflect: true)"))
          }
        }
      }
    } header: {
      Text("Activity")
    }
  }
  private var downloadsLink: some View {
    LiveSettingsLinkRow(
      title: "Downloads",
      icon: "arrow.down.circle",
      badge: downloadCenter.activeCount
    ) {
      LiveDownloadsView(
        dependencies: coordinator.dependencies,
        center: downloadCenter
      )
    }
  }
  @ViewBuilder var supportSection: some View {
    if let user = coordinator.currentUser,
      !user.id.hasPrefix("guest:") {
      Section {
        LiveSettingsLinkRow(
          title: "Report a problem",
          icon: "ladybug.fill"
        ) {
          LiveReportIssueView(
            service: coordinator.dependencies.bugReportsService
          )
        }
        if user.role == .admin || user.role == .moderator {
          LiveSettingsLinkRow(
            title: "Manage bug reports",
            icon: "ladybug.fill"
          ) {
            LiveAdminBugReportsView(
              service: coordinator.dependencies.bugReportsService,
              canCreateGitHubIssue: user.role == .admin
            )
          }
        }
      } header: {
        Text("Support")
      }
    }
  }

  @ViewBuilder var administrationSection: some View {
    if let user = coordinator.currentUser, user.role == .admin {
      Section {
        LiveSettingsLinkRow(
          title: "Admin console",
          icon: "person.3.fill"
        ) {
          LiveAdminConsoleView(
            dependencies: coordinator.dependencies,
            currentUserID: user.id
          )
        }
      } header: {
        Text("Administration")
      }
    }
  }

  var signOutSection: some View {
    Section {
      Button {
        confirmsSignOut = true
      } label: {
        Text("Sign out")
          .font(.body.weight(.semibold))
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity)
          .frame(height: 44)
      }
      .accessibilityIdentifier("live.account.sign-out")
      .liveConfirmPopover(
        isPresented: $confirmsSignOut,
        title: "Sign out of this instance?",
        message: "You can sign back in any time.",
        confirmTitle: "Sign out"
      ) {
        Task { await coordinator.signOut() }
      }
    }
  }

  @ViewBuilder
  private func accountAvatar(for user: AuthUser) -> some View {
    if let code = user.avatarCode,
      user.avatarType?.lowercased() == "emoji",
      let glyph = LiveAvatar.emoji(fromHexCode: code)
    {
      Text(glyph)
        .font(.system(size: 24))
        .frame(width: 46, height: 46)
        .background(palette.groupedSurface, in: Circle())
    } else if user.avatarURL != nil {
      LiveRemoteImage(url: user.avatarURL)
        .frame(width: 46, height: 46)
        .clipShape(Circle())
    } else {
      Image(systemName: "person.crop.circle")
        .font(.system(size: 34))
        .foregroundStyle(.secondary)
        .frame(width: 46, height: 46)
    }
  }
}
