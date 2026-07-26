import SwiftUI

struct DemoWatchActionsView: View {
  @EnvironmentObject var session: DemoSessionStore
  let video: DemoVideo
  @Binding var audioOnly: Bool
  @Binding var toastMessage: String?

  @State private var presentsDownload = false
  @State private var presentsSave = false
  @State private var presentsReport = false

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 10) {
        actionButton(
          isFavorite ? "Favorited" : "Favorite",
          systemImage: isFavorite ? "star.fill" : "star",
          active: isFavorite
        ) {
          session.toggleFavorite(video.id)
          showToast(isFavorite ? "Saved to Favorites" : "Removed from Favorites")
        }

        actionButton(
          isDownloaded ? "Downloaded" : "Download",
          systemImage: isDownloaded ? "checkmark.circle.fill" : "arrow.down.to.line",
          active: isDownloaded
        ) {
          presentsDownload = true
        }

        actionButton(
          "Audio only",
          systemImage: "headphones",
          active: audioOnly
        ) {
          let wasPlaying = session.playerController.state == .playing
          audioOnly.toggle()
          session.playerController.resumeAfterPresentationChange(
            if: wasPlaying
          )
          showToast(audioOnly ? "Audio-only mode enabled" : "Video restored")
        }

        ShareLink(
          item: "Mock share: \(video.title) — \(video.channel)",
          subject: Text(video.title),
          message: Text("Watch \(video.title) on TypeType")
        ) {
          actionLabel("Share", systemImage: "square.and.arrow.up", active: false)
        }
        .buttonStyle(.plain)

        actionButton("Save", systemImage: "text.badge.plus") {
          presentsSave = true
        }

        Menu {
          Button(
            isInWatchLater ? "Remove from Watch later" : "Add to Watch later",
            systemImage: "clock"
          ) {
            session.toggleWatchLater(video.id)
            showToast(
              isInWatchLater
                ? "Removed from Watch later"
                : "Saved to Watch later"
            )
          }
          Button(
            isVideoBlocked ? "Unblock video" : "Block video",
            systemImage: "hand.raised",
            role: isVideoBlocked ? nil : .destructive
          ) {
            session.toggleBlockedVideo(video.id)
            showToast(isVideoBlocked ? "Video unblocked" : "Video blocked")
          }
          Button(
            isChannelBlocked ? "Unblock channel" : "Block channel",
            systemImage: "person.crop.circle.badge.xmark",
            role: isChannelBlocked ? nil : .destructive
          ) {
            session.toggleBlockedChannel(video.channel)
            showToast(
              isChannelBlocked
                ? "\(video.channel) unblocked"
                : "\(video.channel) blocked"
            )
          }
        } label: {
          actionLabel("More", systemImage: "ellipsis", active: false)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("demo.watch.more")

        actionButton("Report", systemImage: "ladybug") {
          presentsReport = true
        }
      }
    }
    .scrollIndicators(.hidden)
    .sheet(isPresented: $presentsDownload) {
      DemoDownloadSheet(video: video, onDone: showToast)
    }
    .sheet(isPresented: $presentsSave) {
      DemoSaveToPlaylistSheet(video: video, onDone: showToast)
    }
    .sheet(isPresented: $presentsReport) {
      DemoReportSheet {
        showToast("Report saved for this mock session")
      }
    }
    .accessibilityIdentifier("demo.watch.actions")
  }

}
