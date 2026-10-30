import SwiftUI

struct LiveSubscriptionChannelRow<GroupActions: View>: View {
  let channel: LiveSubscription
  let groupNames: [String]
  let onOpen: () -> Void
  let onUnsubscribe: () -> Void
  @ViewBuilder let groupActions: () -> GroupActions

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onOpen) {
        HStack(spacing: 12) {
          LiveRemoteImage(url: URL(string: channel.avatarURL))
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 3) {
            Text(channel.name)
              .font(.body.weight(.semibold))
              .foregroundStyle(.primary)
              .lineLimit(1)
            HStack(spacing: 5) {
              if let service {
                LiveServiceLogo(service: service, size: 13)
              }
              Text(subtitle)
                .lineLimit(1)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
          }
          Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityHint(Text("Opens the channel"))

      Menu {
        actions
      } label: {
        Image(systemName: "ellipsis")
          .font(.body.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 32, height: 44)
          .contentShape(Rectangle())
      }
      .accessibilityLabel(Text("More actions for \(channel.name)"))
    }
    .swipeActions(edge: .trailing) {
      Button("Unsubscribe", systemImage: "person.badge.minus", role: .destructive, action: onUnsubscribe)
    }
    .contextMenu { actions }
    .accessibilityIdentifier("live.subscriptions.channel")
  }

  @ViewBuilder private var actions: some View {
    groupActions()
    Divider()
    Button("Unsubscribe", systemImage: "person.badge.minus", role: .destructive, action: onUnsubscribe)
  }

  private var service: VideoService? {
    VideoService.hosting(channel.channelURL)
  }

  private var subtitle: String {
    if !groupNames.isEmpty {
      return groupNames.joined(separator: ", ")
    }
    return service?.name ?? String(localized: "Subscribed")
  }
}
