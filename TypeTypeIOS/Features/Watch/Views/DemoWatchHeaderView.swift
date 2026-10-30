import SwiftUI

struct DemoWatchHeaderView: View {
  @Environment(\.themePalette) private var palette
  @EnvironmentObject private var session: DemoSessionStore
  @ObservedObject var controller: DemoPlayerController
  let video: DemoVideo
  let onChannelSelect: () -> Void
  @State private var isLiked = false
  @State private var isDisliked = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(video.title)
          .font(.title3.weight(.semibold))
          .foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 8) {
          playbackStatus
          Text("\(video.metadata) · 2008 · CC BY 3.0")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      ViewThatFits(in: .horizontal) {
        HStack {
          channel
          Spacer()
          reactions
        }
        VStack(alignment: .leading, spacing: 14) {
          channel
          reactions
        }
      }
    }
  }

  private var playbackStatus: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(statusColor)
        .frame(width: 7, height: 7)
      Text(statusText)
    }
    .font(.caption.weight(.medium))
    .foregroundStyle(.secondary)
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("demo.player.status")
  }

  private var channel: some View {
    HStack(spacing: 11) {
      Button(action: onChannelSelect) {
        HStack(spacing: 11) {
          DemoChannelAvatar(
            name: video.channel,
            artwork: video.artwork,
            size: 38
          )
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
              Text(video.channel)
              Image(systemName: "checkmark.seal.fill")
                .font(.caption2)
                .foregroundStyle(Color(red: 1, green: 0.31, blue: 0.34))
                .accessibilityLabel("Verified")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            Text("2.1M subscribers")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open \(video.channel) channel")
      .accessibilityIdentifier("demo.watch.channel")

      Button(isSubscribed ? "Subscribed" : "Subscribe") {
        withAnimation(.snappy) {
          session.toggleFollowedChannel(channelID)
        }
      }
        .buttonStyle(.borderedProminent)
        .tint(isSubscribed ? palette.surface : .accentColor)
        .foregroundStyle(isSubscribed ? Color.primary : Color.white)
        .accessibilityIdentifier("demo.watch.subscribe")
    }
  }

  private var reactions: some View {
    HStack(spacing: 0) {
      Button {
        isLiked.toggle()
        if isLiked { isDisliked = false }
      } label: {
        Label(isLiked ? "18K + 1" : "18K", systemImage: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
      }
        .padding(.horizontal, 12)
      Divider().frame(height: 18)
      Button {
        isDisliked.toggle()
        if isDisliked { isLiked = false }
      } label: {
        Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
      }
        .padding(.horizontal, 12)
    }
    .font(.subheadline)
    .foregroundStyle(.primary)
    .frame(height: 38)
    .background(palette.surface)
    .clipShape(Capsule())
    .buttonStyle(.plain)
    .accessibilityIdentifier("demo.watch.reactions")
  }

  private var statusText: String {
    switch controller.state {
    case .playing:
      return "Playing"
    case .paused:
      return "Paused"
    case .failed:
      return "Unavailable"
    default:
      return "Loading"
    }
  }

  private var statusColor: Color {
    switch controller.state {
    case .playing:
      return .green
    case .failed:
      return .red
    default:
      return .orange
    }
  }

  private var channelID: String {
    let name = video.channel.lowercased()
    if name.contains("blender") { return "blender" }
    if name.contains("typetype") { return "typetype" }
    if name.contains("pipepipe") { return "pipepipe" }
    if name.contains("open") || name.contains("community") {
      return "open-media"
    }
    return "self-hosted"
  }

  private var isSubscribed: Bool {
    session.followedChannelIDs.contains(channelID)
  }
}
