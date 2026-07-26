import SwiftUI

struct DemoVideoCard: View {
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  let onSelect: (DemoVideo) -> Void

  var body: some View {
    Group {
      if session.hiddenVideoIDs.contains(video.id) {
        hiddenCard
      } else {
        videoCard
      }
    }
  }

  private var videoCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button {
        onSelect(video)
      } label: {
        DemoArtworkView(video: displayVideo)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("demo.home.video.\(video.id)")

      HStack(alignment: .top, spacing: 10) {
        DemoChannelAvatar(name: video.channel, artwork: video.artwork)

        Button {
          onSelect(video)
        } label: {
          metadata
        }
        .buttonStyle(.plain)

        Spacer(minLength: 0)

        DemoVideoCardOptions(video: video)
      }
    }
    .overlay(alignment: .topTrailing) {
      if isFavorite || isInWatchLater || isQueued {
        stateBadges
      }
    }
  }

  private var metadata: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(displayVideo.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
      Text(video.channel)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      Text(video.metadata)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .contentShape(Rectangle())
  }

  private var stateBadges: some View {
    HStack(spacing: 5) {
      if isFavorite {
        Image(systemName: "star.fill")
      }
      if isInWatchLater {
        Image(systemName: "clock.fill")
      }
      if isQueued {
        Image(systemName: "text.badge.checkmark")
      }
    }
    .font(.caption2)
    .foregroundStyle(.white)
    .padding(7)
    .background(.black.opacity(0.68))
    .clipShape(Capsule())
    .padding(8)
    .allowsHitTesting(false)
  }

  private var hiddenCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "eye.slash.fill")
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 3) {
        Text("Recommendation hidden")
          .font(.subheadline.weight(.semibold))
        Text(video.title)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer()
      Button("Undo") {
        withAnimation(.snappy) {
          session.toggleHidden(video.id)
        }
      }
      .font(.caption.weight(.semibold))
    }
    .foregroundStyle(.primary)
    .padding(16)
    .frame(maxWidth: .infinity, minHeight: 86)
    .background(DemoTheme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var isFavorite: Bool {
    session.favoriteVideoIDs.contains(video.id)
  }

  private var isInWatchLater: Bool {
    session.watchLaterVideoIDs.contains(video.id)
  }

  private var isQueued: Bool {
    session.queuedVideoIDs.contains(video.id)
  }
  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }
}
