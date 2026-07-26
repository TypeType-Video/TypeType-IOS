import SwiftUI

struct DemoSearchChannelRow: View {
  @EnvironmentObject private var session: DemoSessionStore
  let channel: DemoSearchChannel
  let onSelect: () -> Void

  init(channel: DemoSearchChannel, onSelect: @escaping () -> Void) {
    self.channel = channel
    self.onSelect = onSelect
  }

  var body: some View {
    HStack(spacing: 13) {
      Button(action: onSelect) {
        HStack(spacing: 13) {
          DemoChannelAvatar(
            name: channel.name,
            artwork: channel.artwork,
            size: 54
          )

          VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
              Text(channel.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
              if channel.isVerified {
                Image(systemName: "checkmark.seal.fill")
                  .font(.caption2)
                  .foregroundStyle(Color(red: 1, green: 0.31, blue: 0.34))
                  .accessibilityLabel("Verified")
              }
            }
            Text("\(channel.handle) · \(channel.followers)")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Text(channel.summary)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
        }
      }
      .buttonStyle(.plain)

      Spacer(minLength: 4)

      Button {
        if isAllowed {
          session.globalAllowedChannels.removeAll { $0 == channel.name }
        } else {
          session.globalAllowedChannels.append(channel.name)
        }
      } label: {
        Image(systemName: isAllowed ? "checkmark.shield.fill" : "shield")
          .frame(width: 34, height: 34)
          .background(DemoTheme.elevatedSurface, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isAllowed ? "Remove allowed channel" : "Allow channel")

      Button {
        withAnimation(.snappy) {
          session.toggleFollowedChannel(channel.id)
        }
      } label: {
        Text(isFollowing ? "Following" : "Follow")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 12)
          .frame(height: 34)
          .background(
            isFollowing
              ? Color.secondary
              : Color.accentColor
          )
          .clipShape(Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(12)
    .background(DemoTheme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .accessibilityIdentifier("demo.search.channel.\(channel.id)")
  }

  private var isFollowing: Bool {
    session.followedChannelIDs.contains(channel.id)
  }

  private var isAllowed: Bool {
    session.globalAllowedChannels.contains(channel.name)
  }
}
