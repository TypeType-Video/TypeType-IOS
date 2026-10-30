import SwiftUI

struct LiveSettingsAccountCard: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var connectivity: LiveConnectivityMonitor
  @Environment(\.themePalette) private var palette

  var body: some View {
    NavigationLink {
      LiveSettingsAccountsView(coordinator: coordinator)
    } label: {
      HStack(spacing: 14) {
        LiveToolbarAvatar(user: coordinator.currentUser, size: 58)
          .overlay {
            Circle().strokeBorder(palette.accent.opacity(0.35), lineWidth: 1.5)
          }
        VStack(alignment: .leading, spacing: 3) {
          Text(displayName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
          Text(instanceLine)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          statusLine
        }
        Spacer(minLength: 0)
      }
      .padding(.vertical, 6)
    }
    .accessibilityElement(children: .combine)
    .accessibilityHint(Text("Opens instances and accounts"))
    .accessibilityIdentifier("live.settings.account")
  }

  private var displayName: String {
    guard let user = coordinator.currentUser, !user.id.hasPrefix("guest:") else {
      return String(localized: "Guest")
    }
    return user.publicUsername ?? String(localized: "Guest")
  }

  private var instanceLine: String {
    let name = coordinator.instance?.name ?? coordinator.selectedServer?.name ?? "TypeType"
    guard let address = coordinator.selectedServer?.baseURLString,
      let host = URL(string: address)?.host()
    else { return name }
    return name == host ? host : "\(name) · \(host)"
  }

  private var statusLine: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(status.color)
        .frame(width: 7, height: 7)
      Text(status.title)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
    }
  }

  private var status: (title: LocalizedStringKey, color: Color) {
    switch connectivity.status {
    case .online: ("Connected", .green)
    case .offline: ("Offline", .orange)
    case .checking: ("Checking connection", Color.secondary)
    }
  }
}
