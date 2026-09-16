import SwiftUI

struct LiveChannelHeaderView: View {
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
          .aspectRatio(4.4, contentMode: .fit)
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
                .foregroundStyle(DemoTheme.accent)
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

        if isSubscribed, isNotificationsAvailable {
          Button(action: onNotifications) {
            Group {
              if isChangingNotifications {
                ProgressView()
              } else {
                Image(
                  systemName: isNotificationsEnabled
                    ? "bell.fill"
                    : "bell.slash"
                )
                .font(.body.weight(.semibold))
              }
            }
            .frame(width: 34, height: 34)
          }
          .buttonStyle(.bordered)
          .tint(
            isNotificationsEnabled
              ? DemoTheme.accent
              : DemoTheme.elevatedSurface
          )
          .buttonBorderShape(.circle)
          .disabled(isChangingNotifications)
          .accessibilityLabel(
            isNotificationsEnabled
              ? "Turn off channel notifications"
              : "Turn on channel notifications"
          )
          .accessibilityIdentifier("live.channel.notifications")
        }

        Button(action: onSubscription) {
          if isChangingSubscription {
            ProgressView()
              .frame(minWidth: 76)
          } else {
            Text(isSubscribed ? "Subscribed" : "Subscribe")
              .frame(minWidth: 76)
          }
        }
        .buttonStyle(.borderedProminent)
        .tint(
          isSubscribed
            ? DemoTheme.elevatedSurface
            : DemoTheme.accent
        )
        .buttonBorderShape(.capsule)
        .disabled(isChangingSubscription)
        .accessibilityIdentifier("live.channel.subscription")
      }

      if !channel.description.isEmpty {
        Text(channel.description)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(3)
      }
    }
  }
}
