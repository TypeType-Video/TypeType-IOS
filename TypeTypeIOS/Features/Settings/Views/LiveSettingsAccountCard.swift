import SwiftUI

struct LiveSettingsAccountCard: View {
  @ObservedObject var coordinator: RootCoordinator

  var body: some View {
    NavigationLink {
      LiveSettingsAccountsView(coordinator: coordinator)
    } label: {
      LiveSettingsAccountSummary(coordinator: coordinator)
    }
    .accessibilityHint(Text("Opens instances and accounts"))
    .accessibilityIdentifier("live.settings.account")
  }
}

struct LiveSettingsAccountSummary: View {
  @ObservedObject var coordinator: RootCoordinator
  @Environment(\.themePalette) private var palette
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    let layout = dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
      : AnyLayout(HStackLayout(spacing: 14))
    layout {
      LiveToolbarAvatar(user: coordinator.currentUser, size: 58)
        .overlay {
          Circle().strokeBorder(palette.accent.opacity(0.35), lineWidth: 1.5)
        }
      VStack(alignment: .leading, spacing: 3) {
        Text(displayName)
          .font(.title3.weight(.semibold))
          .foregroundStyle(.primary)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
        Text(instanceLine)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
      }
      Spacer(minLength: 0)
    }
    .padding(.vertical, 6)
    .accessibilityElement(children: .combine)
  }

  private var displayName: String {
    guard let user = coordinator.currentUser, !user.id.hasPrefix("guest:") else {
      return String(localized: "Guest")
    }
    if let name = user.publicUsername, !name.isEmpty { return name }
    let serverID = coordinator.selectedServer?.id ?? ""
    return coordinator.dependencies.sessionStore.session(forServerID: serverID)?.accountIdentifier
      ?? user.role.title
  }

  private var instanceLine: String {
    let name = coordinator.instance?.name ?? coordinator.selectedServer?.name ?? "TypeType"
    guard let address = coordinator.selectedServer?.baseURLString,
      let host = URL(string: address)?.host()
    else { return name }
    return name == host ? host : "\(name) · \(host)"
  }
}
