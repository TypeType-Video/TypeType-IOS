import SwiftUI

struct LiveNotificationRow: View {
  let notification: LiveNotification
  @ObservedObject private var deArrowStore: LiveDeArrowStore
  let onOpen: () -> Void

  init(
    notification: LiveNotification,
    deArrowStore: LiveDeArrowStore,
    onOpen: @escaping () -> Void
  ) {
    self.notification = notification
    self.deArrowStore = deArrowStore
    self.onOpen = onOpen
  }

  var body: some View {
    Button(action: onOpen) {
      HStack(alignment: .top, spacing: 12) {
        LiveRemoteImage(url: branding.thumbnailURL)
          .aspectRatio(16 / 9, contentMode: .fill)
          .frame(width: 112, height: 63)
          .clipped()
          .clipShape(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
          )
        VStack(alignment: .leading, spacing: 5) {
          Text(branding.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
          HStack(spacing: 6) {
            LiveRemoteImage(
              url: URL(string: notification.channelAvatarURL)
            )
            .frame(width: 18, height: 18)
            .clipShape(Circle())
            Text(notification.channelName)
              .lineLimit(1)
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          Text(date.formatted(.relative(presentation: .named)))
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        Spacer(minLength: 0)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("live.notifications.row")
    .task { await deArrowStore.prepare(notification.video) }
  }

  private var date: Date {
    let value = notification.publishedAt > 10_000_000_000
      ? TimeInterval(notification.publishedAt) / 1_000
      : TimeInterval(notification.publishedAt)
    return Date(timeIntervalSince1970: value)
  }

  private var branding: LiveVideoBranding {
    deArrowStore.branding(for: notification.video)
  }
}
