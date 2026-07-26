import SwiftUI

struct DemoChannelDetailHeader: View {
  @EnvironmentObject private var session: DemoSessionStore
  let channel: DemoSearchChannel

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      LinearGradient(
        colors: [bannerColor.opacity(0.78), .black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .frame(height: 104)
      .overlay(alignment: .trailing) {
        Image(channel.artwork.rawValue)
          .resizable()
          .interpolation(.none)
          .scaledToFit()
          .frame(width: 126, height: 92)
          .padding(.trailing, 12)
      }
      .clipShape(RoundedRectangle(cornerRadius: 16))

      HStack(alignment: .center, spacing: 12) {
        DemoChannelAvatar(
          name: channel.name,
          artwork: channel.artwork,
          size: 62
        )

        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 6) {
            Text(channel.name)
              .font(.headline.weight(.bold))
              .lineLimit(2)
            if channel.isVerified {
              Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(session.preferences.accentColor)
                .accessibilityLabel("Verified")
            }
          }
          Text(channel.handle)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(channel.followers)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 4)

        Button {
          session.toggleFollowedChannel(channel.id)
        } label: {
          Text(isFollowing ? "Subscribed" : "Subscribe")
            .font(.caption.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .tint(
          isFollowing
            ? Color.secondary.opacity(0.28)
            : session.preferences.accentColor
        )
        .foregroundStyle(isFollowing ? Color.primary : Color.white)
      }

      Text(channel.summary)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      HStack {
        Button {
          if isAllowed {
            session.globalAllowedChannels.removeAll { $0 == channel.name }
          } else {
            session.globalAllowedChannels.append(channel.name)
          }
        } label: {
          Label(
            isAllowed ? "In family list" : "Add to family list",
            systemImage: isAllowed
              ? "checkmark.shield.fill"
              : "person.badge.shield.checkmark"
          )
          .font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.small)

        Spacer()
      }
    }
  }

  private var isFollowing: Bool {
    session.followedChannelIDs.contains(channel.id)
  }

  private var isAllowed: Bool {
    session.globalAllowedChannels.contains(channel.name)
  }

  private var bannerColor: Color {
    switch channel.artwork {
    case .television:
      return .indigo
    case .dog:
      return .orange
    case .cat:
      return .purple
    case .bird:
      return .cyan
    case .pipePipe:
      return Color(red: 0.03, green: 0.48, blue: 0.68)
    case .typeType:
      return Color(red: 0.94, green: 0.27, blue: 0.29)
    }
  }
}
