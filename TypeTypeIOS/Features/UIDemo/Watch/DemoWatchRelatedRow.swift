import SwiftUI

struct DemoWatchRelatedRow: View {
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  let onSelect: (DemoVideo) -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Button {
        onSelect(video)
      } label: {
        DemoArtworkView(video: displayVideo, showsDuration: false)
          .frame(width: 126, height: 71)
          .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
          .overlay(alignment: .bottomTrailing) {
            Text(video.duration)
              .font(.caption2.monospacedDigit().weight(.bold))
              .foregroundStyle(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 3)
              .background(.black.opacity(0.9))
              .clipShape(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
              )
              .padding(5)
              .accessibilityLabel("Duration \(video.duration)")
          }
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("demo.watch.related.thumbnail.\(video.id)")

      Button {
        onSelect(video)
      } label: {
        VStack(alignment: .leading, spacing: 3) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      optionsMenu
    }
    .frame(maxWidth: .infinity, minHeight: 71, alignment: .leading)
    .background(alignment: .topLeading) {
      Color.clear
        .frame(width: 1, height: 1)
        .accessibilityElement()
        .accessibilityLabel("Related video")
        .accessibilityIdentifier("demo.watch.related.\(video.id)")
    }
  }

  private var optionsMenu: some View {
    Menu {
      Button(
        isQueued ? "Remove from queue" : "Add to queue",
        systemImage: "text.line.last.and.arrowtriangle.forward"
      ) {
        session.toggleQueue(video.id)
      }
      Button(
        isWatchLater ? "Remove from Watch later" : "Watch later",
        systemImage: "clock"
      ) {
        session.toggleWatchLater(video.id)
      }
      Button(
        isFavorite ? "Remove from Favorites" : "Save to Favorites",
        systemImage: "star"
      ) {
        session.toggleFavorite(video.id)
      }
      Divider()
      Button("Not interested", systemImage: "eye.slash") {
        withAnimation(.snappy) {
          session.toggleHidden(video.id)
        }
      }
    } label: {
      Image(systemName: "ellipsis")
        .foregroundStyle(.secondary)
        .frame(width: 28, height: 32, alignment: .top)
        .contentShape(Rectangle())
    }
    .accessibilityLabel("More actions for \(video.title)")
  }

  private var displayVideo: DemoVideo {
    video.branded(using: session.preferences)
  }

  private var isQueued: Bool {
    session.queuedVideoIDs.contains(video.id)
  }

  private var isWatchLater: Bool {
    session.watchLaterVideoIDs.contains(video.id)
  }

  private var isFavorite: Bool {
    session.favoriteVideoIDs.contains(video.id)
  }
}
