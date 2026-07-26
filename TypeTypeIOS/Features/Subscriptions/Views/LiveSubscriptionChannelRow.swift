import SwiftUI

struct LiveSubscriptionChannelRow: View {
  let channel: LiveSubscription
  let onOpen: () -> Void
  let onUnsubscribe: () -> Void

  var body: some View {
    Button(action: onOpen) {
      HStack(spacing: 14) {
        LiveRemoteImage(url: URL(string: channel.avatarURL))
          .frame(width: 54, height: 54)
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 4) {
          Text(channel.name)
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(1)
          Text(subscribedText)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button(
        "Unsubscribe",
        systemImage: "bell.slash",
        role: .destructive,
        action: onUnsubscribe
      )
    }
    .accessibilityIdentifier("live.subscriptions.channel")
  }

  private var subscribedText: String {
    guard channel.subscribedAt > 0 else { return "Subscribed" }
    let interval = channel.subscribedAt > 10_000_000_000
      ? TimeInterval(channel.subscribedAt) / 1_000
      : TimeInterval(channel.subscribedAt)
    let date = Date(timeIntervalSince1970: interval).formatted(
      date: .abbreviated,
      time: .omitted
    )
    return "Subscribed \(date)"
  }
}
