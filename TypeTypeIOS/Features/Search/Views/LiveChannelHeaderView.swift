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
        // Compact banner (dev feedback, plan task 5): a slim strip above the
        // identity row instead of the oversized banner block.
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
              ? palette.accent
              : palette.elevatedSurface
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
            ? palette.elevatedSurface
            : palette.accent
        )
        .buttonBorderShape(.capsule)
        .disabled(isChangingSubscription)
        .accessibilityIdentifier("live.channel.subscription")
      }
      // The description lives in the About tab: the header is identity +
      // subscribe only (dev feedback, plan task 5).
    }
  }
}
