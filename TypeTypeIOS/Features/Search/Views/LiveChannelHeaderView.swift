import SwiftUI

struct LiveChannelHeaderView: View {
  @Environment(\.themePalette) private var palette
  let channel: LiveChannelPage
  let isSubscribed: Bool
  let isChangingSubscription: Bool
  var isNotificationsAvailable = false
  var isNotificationsEnabled = false
  var isChangingNotifications = false
  var onNotifications: () -> Void = {}
  let onSubscription: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if !channel.bannerURL.isEmpty {
        LiveRemoteImage(url: channel.banner)
          .frame(maxWidth: .infinity)
          .aspectRatio(8, contentMode: .fit)
          .clipped()
          .clipShape(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
          )
      }

      HStack(spacing: 13) {
        LiveRemoteImage(url: channel.avatar)
          .frame(width: 58, height: 58)
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 5) {
            Text(channel.name)
              .font(.headline)
              .lineLimit(1)
            if channel.isVerified {
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(palette.accent)
                .accessibilityLabel("Verified")
            }
          }
          Text(
            LiveVideoMetadataFormatter.subscribers(
              channel.subscriberCount
            )
          )
          .font(.caption)
          .foregroundStyle(.secondary)
        }

        Spacer()

        if isChangingSubscription {
          ProgressView()
            .frame(width: 44, height: 34)
        } else if isSubscribed {
          subscribedMenu
        } else {
          Button("Subscribe", action: onSubscription)
            .buttonStyle(.borderedProminent)
            .tint(palette.accent)
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("live.channel.subscription")
        }
      }
    }
  }

  private var subscribedMenu: some View {
    Menu {
      if isNotificationsAvailable {
        Button(
          isNotificationsEnabled ? "Turn off notifications" : "Turn on notifications",
          systemImage: isNotificationsEnabled ? "bell.slash" : "bell",
          action: onNotifications
        )
        .disabled(isChangingNotifications)
      }
      Button("Unsubscribe", systemImage: "person.badge.minus", role: .destructive, action: onSubscription)
    } label: {
      HStack(spacing: 6) {
        Image(systemName: isNotificationsEnabled ? "bell.fill" : "checkmark")
        Image(systemName: "chevron.down")
          .font(.caption.weight(.bold))
      }
      .font(.body.weight(.semibold))
      .foregroundStyle(.primary)
      .padding(.horizontal, 14)
      .frame(height: 34)
      .background(.quaternary, in: Capsule())
    }
    .accessibilityLabel(Text("Subscribed"))
    .accessibilityHint(Text("Shows notification and unsubscribe options"))
    .accessibilityIdentifier("live.channel.subscription")
  }
}
