import SwiftUI

struct DemoVideoCardOptions: View {
  @EnvironmentObject private var session: DemoSessionStore
  let video: DemoVideo
  @State private var presentsSaveSheet = false

  var body: some View {
    Menu {
      Button {
        session.toggleQueue(video.id)
      } label: {
        Label(
          isQueued ? "Remove from queue" : "Add to queue",
          systemImage: isQueued ? "text.badge.minus" : "text.badge.plus"
        )
      }
      Button {
        session.toggleWatchLater(video.id)
      } label: {
        Label(
          isInWatchLater ? "Remove from Watch later" : "Save to Watch later",
          systemImage: isInWatchLater ? "clock.badge.xmark" : "clock.badge.plus"
        )
      }
      Button("Save to playlist", systemImage: "rectangle.stack.badge.plus") {
        presentsSaveSheet = true
      }
      Button {
        session.toggleFavorite(video.id)
      } label: {
        Label(
          isFavorite ? "Remove from Favorites" : "Add to Favorites",
          systemImage: isFavorite ? "star.slash" : "star"
        )
      }
      Divider()
      Button(
        isVideoBlocked ? "Unblock video" : "Block video",
        systemImage: "nosign"
      ) {
        session.toggleBlockedVideo(video.id)
      }
      Button(
        isChannelBlocked ? "Unblock channel" : "Block channel",
        systemImage: "person.crop.circle.badge.xmark"
      ) {
        session.toggleBlockedChannel(video.channel)
      }
      Button("Not interested", systemImage: "eye.slash", role: .destructive) {
        withAnimation(.snappy) {
          session.toggleHidden(video.id)
        }
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.primary.opacity(0.68))
        .frame(width: 34, height: 34)
        .contentShape(Rectangle())
    }
    .accessibilityLabel("Video options")
    .sheet(isPresented: $presentsSaveSheet) {
      DemoSaveToPlaylistSheet(video: video) { _ in }
    }
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

  private var isVideoBlocked: Bool {
    session.blockedVideoIDs.contains(video.id)
  }

  private var isChannelBlocked: Bool {
    session.blockedChannelNames.contains(video.channel)
  }
}
