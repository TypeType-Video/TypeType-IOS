import SwiftUI

struct DemoSubscriptionChannelRow: View {
  @EnvironmentObject private var session: DemoSessionStore
  let channel: DemoSubscriptionChannel
  let onSelect: () -> Void

  init(
    channel: DemoSubscriptionChannel,
    onSelect: @escaping () -> Void
  ) {
    self.channel = channel
    self.onSelect = onSelect
  }

  var body: some View {
    HStack(spacing: 14) {
      Button(action: onSelect) {
        HStack(spacing: 14) {
          DemoChannelAvatar(name: channel.name, artwork: channel.artwork)

          VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 7) {
              Text(channel.name)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
              if channel.isNew {
                Circle()
                  .fill(Color(red: 1, green: 0.3, blue: 0.34))
                  .frame(width: 7, height: 7)
                  .accessibilityLabel("New videos")
              }
            }
            Text("\(channel.handle) · \(channel.followers)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .buttonStyle(.plain)

      Spacer()

      Button(isFollowing ? "Following" : "Follow") {
        withAnimation(.snappy) {
          session.toggleFollowedChannel(channel.id)
        }
      }
        .font(.caption.weight(.semibold))
        .buttonStyle(.bordered)
        .tint(isFollowing ? .secondary : .accentColor)
    }
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .accessibilityIdentifier("demo.subscriptions.channel.\(channel.id)")
  }

  private var isFollowing: Bool {
    session.followedChannelIDs.contains(channel.id)
  }
}
