import SwiftUI

struct LiveTwitchStreamCard: View {
  let stream: LiveTwitchStream

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      LiveTwitchThumbnail(url: stream.previewURL) {
        LiveTwitchBadge(text: Text("LIVE"), tint: .red)
      } trailing: {
        LiveTwitchBadge(text: Text("\(LiveTwitchFormat.count(stream.viewers)) watching"), tint: .black.opacity(0.75))
      }
      HStack(alignment: .top, spacing: 10) {
        LiveTwitchAvatar(url: stream.user.avatarURL, size: 36)
        VStack(alignment: .leading, spacing: 3) {
          Text(verbatim: stream.title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
          Text(verbatim: stream.user.name)
            .font(.caption)
            .foregroundStyle(.secondary)
          if let game = stream.game {
            Text(verbatim: game.name)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(stream.user.name) live: \(stream.title)"))
    .accessibilityValue(Text("\(LiveTwitchFormat.count(stream.viewers)) watching"))
    .accessibilityHint(Text("Plays the live."))
    .accessibilityIdentifier("live.twitch.stream.\(stream.user.login)")
  }
}

struct LiveTwitchGameCard: View {
  let game: LiveTwitchGame

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      LiveRemoteImage(url: LiveImageURLResolver.resolve(game.boxArtURL), contentMode: .fill)
        .frame(width: 112, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      Text(verbatim: game.name)
        .font(.caption.weight(.semibold))
        .lineLimit(2, reservesSpace: true)
      if let viewers = game.viewers {
        Text("\(LiveTwitchFormat.count(viewers)) watching")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 112, alignment: .leading)
    .contentShape(Rectangle())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: game.name))
    .accessibilityHint(Text("Shows the lives in this category."))
  }
}

struct LiveTwitchVideoCard: View {
  let title: String
  let previewURL: String
  let duration: Int
  let detail: String
  let action: (() -> Void)?

  var body: some View {
    if let action {
      Button(action: action) { content }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(Text(verbatim: detail))
    } else {
      content
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(Text(verbatim: detail))
    }
  }

  private var content: some View {
    HStack(alignment: .top, spacing: 12) {
      LiveTwitchThumbnail(url: previewURL) {
        EmptyView()
      } trailing: {
        if duration > 0 {
          LiveTwitchBadge(text: Text(verbatim: LiveVideoMetadataFormatter.duration(Int64(duration))), tint: .black.opacity(0.75))
        }
      }
      .frame(width: 168)
      VStack(alignment: .leading, spacing: 4) {
        Text(verbatim: title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(3)
        Text(verbatim: detail)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .contentShape(Rectangle())
  }
}

struct LiveTwitchThumbnail<Leading: View, Trailing: View>: View {
  let url: String
  @ViewBuilder let leading: () -> Leading
  @ViewBuilder let trailing: () -> Trailing

  var body: some View {
    LiveRemoteImage(url: LiveImageURLResolver.resolve(url), contentMode: .fill)
      .aspectRatio(16 / 9, contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .overlay(alignment: .topLeading) { leading().padding(8) }
      .overlay(alignment: .bottomTrailing) { trailing().padding(8) }
  }
}

struct LiveTwitchBadge: View {
  let text: Text
  let tint: Color

  var body: some View {
    text
      .font(.caption2.weight(.bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .background(tint, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
  }
}

struct LiveTwitchAvatar: View {
  let url: String
  let size: CGFloat

  var body: some View {
    LiveRemoteImage(url: LiveImageURLResolver.resolve(url), contentMode: .fill)
      .frame(width: size, height: size)
      .clipShape(Circle())
      .accessibilityHidden(true)
  }
}
