import SwiftUI

extension LiveHomeView {
  // One leading item: iOS 26 groups items sharing a placement into one glass capsule, and a second item there
  // next to the brand logo did not open its menu.
  @ToolbarContentBuilder
  var brandToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      if viewModel.services.count > 1 {
        Menu {
          ForEach(viewModel.services) { service in
            Button {
              Task {
                await viewModel.selectService(service.id)
              }
            } label: {
              if service.id == viewModel.selectedServiceID {
                Label(service.name, systemImage: "checkmark")
              } else {
                Text(service.name)
              }
            }
            .accessibilityIdentifier(
              "live.home.service.\(service.id)"
            )
          }
        } label: {
          brandLabel(showsChevron: true)
        }
        .accessibilityLabel("Video service")
        .accessibilityValue(Text(verbatim: selectedService.name))
        .accessibilityIdentifier("live.home.service")
      } else {
        brandLabel(showsChevron: false)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(Text(verbatim: selectedService.name))
      }
    }
  }

  @ToolbarContentBuilder
  var accountsToolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      if let user = coordinator.currentUser,
        !user.id.hasPrefix("guest:")
      {
        NavigationLink {
          LiveNotificationsView(dependencies: coordinator.dependencies)
        } label: {
          Image(systemName: "bell")
            .overlay(alignment: .topTrailing) { unreadBadge }
        }
        .accessibilityLabel(
          notificationCenter.unreadCount > 0
            ? "Notifications, \(notificationCenter.unreadCount) unread"
            : "Notifications"
        )
        .accessibilityIdentifier("live.home.notifications")
      }
      LiveSettingsEntry(coordinator: coordinator) {
        Image(systemName: "gearshape")
      }
      .accessibilityLabel("Settings")
      .accessibilityIdentifier("live.home.settings")
      NavigationLink {
        LiveAccountView(coordinator: coordinator)
      } label: {
        LiveToolbarAvatar(user: coordinator.currentUser, size: 30)
      }
      .accessibilityLabel("Account")
      .accessibilityIdentifier("live.home.account")
    }
  }

  @ViewBuilder
  private var unreadBadge: some View {
    let count = notificationCenter.unreadCount
    if count > 0 {
      Text(count > 99 ? "99+" : String(count))
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .frame(minWidth: 16, minHeight: 16)
        .background(Color.red, in: Capsule())
        .offset(x: 9, y: -7)
    }
  }

  private var selectedService: VideoService {
    viewModel.services.first {
      $0.id == viewModel.selectedServiceID
    } ?? viewModel.services[0]
  }

  private func brandLabel(showsChevron: Bool) -> some View {
    HStack(spacing: 8) {
      Image("TypeTypeLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 25, height: 25)
        .accessibilityHidden(true)
      LiveServiceLogo(service: selectedService, size: 22)
      if showsChevron {
        Image(systemName: "chevron.down")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 4)
    .frame(minWidth: 44, minHeight: 44)
    .contentShape(Rectangle())
  }
}

struct LiveToolbarAvatar: View {
  @Environment(\.themePalette) private var palette
  let user: AuthUser?
  let size: CGFloat

  var body: some View {
    Group {
      if let code = user?.avatarCode,
        user?.avatarType?.lowercased() == "emoji",
        let glyph = LiveAvatar.emoji(fromHexCode: code)
      {
        Text(glyph)
          .font(.system(size: size * 0.5))
      } else if let url = user?.avatarURL {
        LiveRemoteImage(url: url)
          .frame(width: size, height: size)
      } else {
        Image(systemName: "person.fill")
          .font(.system(size: size * 0.45))
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: size, height: size)
    .background(palette.groupedSurface, in: Circle())
    .clipShape(Circle())
  }
}
